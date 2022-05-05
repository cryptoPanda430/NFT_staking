// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Rand {

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("coinracer.io");

    struct RandStorage {
        uint256 seed;
    }

    function rndStorage() internal pure returns(RandStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function rand() internal returns(uint256) {
        RandStorage storage ds = rndStorage();
        ds.seed = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, ds.seed)));
        return ds.seed;
    }

    function randInRange(uint256 min, uint256 max) internal returns(uint256) {
        require(min < max, "Random: Invalid range of random");

        uint256 randval = rand();
        uint256 range = max - min + 1;

        return (randval % range + min);
    }
}