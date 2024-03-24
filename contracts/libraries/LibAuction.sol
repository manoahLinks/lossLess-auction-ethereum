// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;

import "./LibAppStorage.sol";

library LibAuction {
    

    function ensureNextBidCanSettleOutstanding (uint256 _currHighestBid, uint256 _bidAmount) external pure returns (bool) {


    }

    // get percenatge based on amount
    function percentageBasedOnAmount (uint256 _totalFee, uint256 _percentage) external pure returns (uint256) {
        return (_percentage * 100) / _totalFee;
    }

}