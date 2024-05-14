// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { TXPadInfo, TXPadUserData, TXPadUserInfo, TXPadGlobalInfo } from "./Structs.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";

library LibXPad {
    using Arrays for uint256[];

    bytes32 internal constant STORAGE_SLOT = keccak256('storage.xpad.hoopx.ai');

 
    struct Layout {
        
        mapping(uint256 => TXPadInfo) xPadProject;
        mapping(address => mapping(uint256 => TXPadUserInfo)) xPadUserInfo;
        mapping(uint256 => TXPadUserData[]) xPadUserData;

        TXPadGlobalInfo xPadGlobalInfo;
    }

    function layout(
    ) 
        internal 
        pure 
        returns (Layout storage l) 
    {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

}