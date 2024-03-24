// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library LibAppStorage {

    // appstorage slot location
    bytes32 constant APP_STORAGE_POSITION =
        keccak256("diamond.standard.app.storage");

    // bids struct
    struct Bids {
        uint256 amount;
        address bidder;
    }

    // auctions struct
    struct AuctionPool {
        uint256 id;
        uint256 collectibleId;
        uint256 minimumBid;
        address winner;
        uint256 currentHighestBid;
        address currentHighestBidder;
        uint256 amountInPool;
        bool isOpen;
        Bids[] bids;
        address owner;
    }
    
    // app layout
    struct Layout {
        // erc20
        string name;
        string symbol;
        uint256 totalSupply;
        uint8 decimals;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;

        // Auction
        address lastFuctionCaller;
        uint256 auctionPoolCount;
        address erc721Address;
        address erc1155Address;
        mapping(uint256 => AuctionPool) auctionPools;
    }

    // function appStorage()
    //     internal
    //     pure
    //     returns (Layout storage a)
    // {
    //     bytes32 position = APP_STORAGE_POSITION;
    //     assembly {
    //         a.slot := position
    //     }
    // }

}