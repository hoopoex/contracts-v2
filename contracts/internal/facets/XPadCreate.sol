// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { TXPadInfo } from "../libraries/Structs.sol";
import { LibXPad } from "../libraries/LibXPad.sol";
import "../../external/Reserve.sol";
import "../libraries/Errors.sol";

contract XPadCreate is OwnableInternal {

    event HANDLE_NEW_XPAD_PROJECT(address indexed reserveAddr,uint256 id,uint256 when);

    function createXPad(
        TXPadInfo memory _params
    ) 
        external 
        onlyOwner 
    {
        LibXPad.Layout storage xs = LibXPad.layout();
        if(xs.xPadProject[_params.xPadProjectId].xPadIsExist)revert Invalid_Action();

        xs.xPadProject[_params.xPadProjectId] = _params;
        xs.xPadGlobalInfo.xPadProjectIds.push(_params.xPadProjectId);

        unchecked {
            xs.xPadGlobalInfo.xPadTotalProjectCount++;
        }

        Reserve reserveContract = new Reserve(_params.xPadDetails.name,_params.projectWalletAddress);
        xs.xPadProject[_params.xPadProjectId].projectReserveContract = address(reserveContract);
        emit HANDLE_NEW_XPAD_PROJECT(address(reserveContract),_params.xPadProjectId,block.timestamp);
    }

}