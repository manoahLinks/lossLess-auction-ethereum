// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/AuctionFacet.sol";
import "forge-std/Test.sol";
import "../contracts/Diamond.sol";
import "../contracts/ERC721Token.sol";
import "../contracts/libraries/LibAppStorage.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    AuctionFacet auctionFacet;
    ERC721Token erc721Token;

    address A = address(0xa);
    address B = address(0xb);
    address C = address(0xc);

    AuctionFacet auction;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        auctionFacet = new AuctionFacet();
        erc721Token = new ERC721Token();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(auctionFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AuctionFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        diamond.setNftToken(address(erc721Token));

        A = mkaddr("staker a");
        B = mkaddr("staker b");
        C = mkaddr("staker c");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();

        AuctionFacet(address(diamond)).mintTo(A);
        AuctionFacet(address(diamond)).mintTo(B);


        auction = AuctionFacet(address(diamond));

    }

    function testCreateAuction () public {
        switchSigner(A);
        erc721Token.mint();
        erc721Token.approve(address(diamond), 1);
        auction.createAuctionPool(1, 1e18);
        LibAppStorage.AuctionPool memory new_auction = auction.getAuction(1);
        assertEq(new_auction.id, 1);
        assertEq(new_auction.owner, A);
    }

    function testPlaceBid () public {
        switchSigner(A);
        erc721Token.mint();
        erc721Token.approve(address(diamond), 1);
        auction.createAuctionPool(1, 1e18);
        switchSigner(B);
        auction.approve(address(diamond), 2e18);
        auction.placeBid(1, 2e18);
        LibAppStorage.AuctionPool memory new_auction = auction.getAuction(1);
        assertEq(new_auction.currentHighestBidder, B);
    }

      function testRevertNotERC721TokenOwner() public {
        switchSigner(A);
        erc721Token.mint();
        switchSigner(B);
        vm.expectRevert("ERC721: Not your nft");
        auction.createAuctionPool(1, 1e18);
    }

     function testRevertIfInsufficientTokenBalance() public {
        switchSigner(C);
        erc721Token.mint();
        erc721Token.approve(address(diamond), 1);
        auction.createAuctionPool(1, 1e18);
        vm.expectRevert("ERC20: Not enough balance");
        auction.placeBid(1, 1e18);
    }


    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

     function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }

    function switchSigner(address _newSigner) public {
        address foundrySigner = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
        if (msg.sender == foundrySigner) {
            vm.startPrank(_newSigner);
        } else {
            vm.stopPrank();
            vm.startPrank(_newSigner);
        }
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}

}
