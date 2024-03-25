// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibAppStorage.sol";
import "../libraries/LibAuction.sol";
import "../libraries/LibDiamond.sol";
import "../interfaces/IERC721.sol";

contract AuctionFacet {

    // app storage
    LibAppStorage.Layout internal layout;

    function setLastFunctionCaller (address _address) internal {
        layout.lastFuctionCaller = _address;
    }

    function calculatePercentage(uint amount) internal pure returns (uint) {
        return (10 * amount) / 100;
    }

    function distributeTenPercent (uint256 _amount, address _outBidder, address _lastInteractor) internal {
        uint256 burnAmount = LibAuction.percentageBasedOnAmount(_amount, 2); // 2%
        uint256 dao = LibAuction.percentageBasedOnAmount(_amount, 2); // 2%
        uint256 outBidder = LibAuction.percentageBasedOnAmount(_amount, 3); // 3%
        uint256 team = LibAuction.percentageBasedOnAmount(_amount, 2); // 2%
        uint256 lastInteractor = LibAuction.percentageBasedOnAmount(_amount, 1); // 1%

        transferFrom(address(this), _outBidder, outBidder);

        transferFrom(address(this), _lastInteractor, lastInteractor);

        transferFrom(address(this), address(0), burnAmount);

        transferFrom(address(this), address(0xc408235a9A01767d70B41C98d92F2dC7B0d959f4), team);

        transferFrom(address(this), address(0xc408235a9A01767d70B41C98d92F2dC7B0d959f4), dao);
    }

    // =============================================
    //        AUCTION FUNCTIONS
    // =============================================

    // create auction pool
    function createAuctionPool(uint256 _collectibleId, uint256 _minimumBid) external {

        uint256 _poolId = layout.auctionPoolCount + 1;

        // sanity check
        require(msg.sender != address(0), "caller can't be address zero");

        // check if caller is the nft owner
        require(IERC721(layout.erc721Address).ownerOf(_collectibleId) == msg.sender, "ERC721: Not your nft");        

        // send collectible to contract account
        IERC721(layout.erc721Address).transferFrom(msg.sender, address(this), _collectibleId);

        // set all action details
        layout.auctionPools[_poolId].id = _poolId;
        layout.auctionPools[_poolId].collectibleId = _collectibleId;
        layout.auctionPools[_poolId].minimumBid = _minimumBid;
        layout.auctionPools[_poolId].isOpen = true;
        layout.auctionPools[_poolId].owner = msg.sender;

        layout.auctionPoolCount ++;
    }


    // close pool
    function closeAuctionPool(uint256 _poolId) external {
        // sanity check
        require(msg.sender != address(0), "caller can't be address zero");

        // check if function caller is owner of auction pool
        require(msg.sender == layout.auctionPools[_poolId].owner, "You are not pool owner");

        // closing pool 
        layout.auctionPools[_poolId].isOpen = false;

        // make transfers between both parties
        // transfer nft to highest bidder
        IERC721(layout.erc721Address).transferFrom(address(this), layout.auctionPools[_poolId].currentHighestBidder, layout.auctionPools[_poolId].collectibleId);

        // send erc20 tokens to auction owner
        transfer(layout.auctionPools[_poolId].owner, layout.auctionPools[_poolId].amountInPool);

    }

    function getAuction(
        uint poolId
    ) external view returns (LibAppStorage.AuctionPool memory) {
        return layout.auctionPools[poolId];
    }

    // placebid function
    function placeBid (uint256 _poolId, uint256 _amount) external {

        // sanity check
        require(msg.sender != address(0), "caller can't be address zero");

        // check amount
        require(_amount > 0, "amount cant be zero");

        require(layout.auctionPools[_poolId].isOpen, "Bidding is closed");

        // check bal of bidder in erc20
        require(layout.balances[msg.sender] >= _amount, "ERC20: Not enough balance");

        require(_amount > layout.auctionPools[_poolId].minimumBid, "Auction: Amount less than current highest bid");

        // check if amount if higher than the last bidder and update current highest bidder
        require(_amount > layout.auctionPools[_poolId].currentHighestBid, "Auction: Amount less than current highest bid");

        uint256 percentCut = calculatePercentage(_amount);

        // distributeTenPercent(percentCut, layout.auctionPools[_poolId].currentHighestBidder, layout.lastFuctionCaller);

        // create bid
        transferFrom(msg.sender, address(this), _amount);

        //model bid 
        LibAppStorage.Bids memory _bid = LibAppStorage.Bids(_amount, msg.sender);

        // update auction pool
        layout.auctionPools[_poolId].currentHighestBid = _amount;

        layout.auctionPools[_poolId].currentHighestBidder = msg.sender;

        // push bid to bidders array
        layout.auctionPools[_poolId].bids.push(_bid);
    }


    // ============================================================
    //            ERC20 FUNCTIONS
    // ============================================================


    // transfer function
    function transfer (address _to, uint256 _amount) internal {

        // checks
        require(msg.sender != address(0), "caller cant be address zero");

        require(layout.balances[msg.sender] >= _amount, "ERC20: No tokens to transfer");

        // add and deductions from accts
        layout.balances[msg.sender] -= _amount;

        layout.balances[_to] += _amount;

        // setting last function caller
        setLastFunctionCaller(msg.sender);
    }

    // transafer from function
    function transferFrom (address _from, address _to, uint256 _amount) internal returns (bool) {

        // checks
        require(msg.sender != address(0), "caller cant be address zero");

        require(layout.balances[_from] >= _amount, "ERC20: No tokens to transfer");

        require(layout.allowances[_from][_to] >= _amount, "ERC20: not enough allowance");

        // add and deductions from accts
        layout.balances[_from] -= _amount;

        layout.balances[_to] += _amount;

        // reduce allowance after transfer
        layout.allowances[_from][_to] -= _amount;

        return true;
    }

    // function approve
    function approve (address _spender, uint256 _amount) external {

         // checks
         require(msg.sender != address(0), "caller cant be address zero");

         layout.allowances[msg.sender][_spender] = _amount;

         // setting last function caller
         setLastFunctionCaller(msg.sender);
    }

    // function mint
    function mint (address _to, uint256 _amount) private {

        layout.balances[_to] += _amount;

        layout.totalSupply += _amount;
    }

    // burn function
    function burn (address _to, uint256 _amount) private {

        layout.balances[_to] -= _amount;

        layout.totalSupply -= _amount;
    }

    function mintTo(address _user) external {
        LibDiamond.enforceIsContractOwner();
        uint256 amount = 100_000_000e18;
        layout.balances[_user] += amount;
        layout.totalSupply += uint96(amount);
        // emit LibAppStorage.Transfer(address(0), _user, amount);
    }

}
