// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "./LibAppStorage.sol";

library LibAuction {


    // get percenatge based on amount
    function percentageBasedOnAmount (uint256 _totalFee, uint256 _percentage) external view returns (uint256) {
        return (_percentage * 100) / _totalFee;
    }

}