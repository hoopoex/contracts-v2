// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { TMembership,TNFT } from "./Structs.sol";

library LibMembership{
    bytes32 internal constant STORAGE_SLOT = keccak256('storage.membership.hoopx.ai');

    uint256 public constant Tortullix = 1e18;
    uint256 public constant Woolvenia = 2e18;
    uint256 public constant Bouncebyte = 3e18;
    uint256 public constant Stagora = 4e18;
    uint256 public constant Honeyheart = 5e18;
    uint256 public constant PiggyPrime = 6e18;
    uint256 public constant HoopX = 7e18;
    uint256 public constant PrimeBull = 8e18;
    uint256 public constant Wolvenix = 9e18;
    uint256 public constant Whalesong = 10e18;

    function checkExistence(
        uint256[] memory _array,
        uint256 _value
    )
        internal 
        pure 
        returns(bool) 
    {
        uint256[] memory array = _array;
        uint256 arrayLength = array.length;
        uint256 value = _value;
        for (uint256 i = 0; i < arrayLength;){
            if (array[i] == value) {
                return true;
            }
            unchecked{
                i++;
            }
        }
        return false;
    }

    struct Layout {
        mapping(address => mapping(uint256 => TNFT)) nft;
        mapping(address => bool) authorizedUser;
        TMembership membership;
    }

    function layout(
    ) 
        internal 
        pure 
        returns 
        (Layout storage l) 
    {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}