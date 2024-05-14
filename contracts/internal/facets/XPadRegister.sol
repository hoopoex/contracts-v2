// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import  "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { Modifiers } from "../libraries/Modifiers.sol";
import { LibStake } from "../libraries/LibStake.sol";
import { LibXPad } from "../libraries/LibXPad.sol";
import "../libraries/Errors.sol";

contract XPadRegister is Modifiers, ReentrancyGuard {

    event HANDLE_REGISTER_XPAD(address indexed addr,uint256 id,uint256 when);

    function xPadRegister(
        uint256 _id
    ) 
        external 
        whenNotContract(msg.sender) 
        nonReentrant 
    {
        LibXPad.Layout storage xs = LibXPad.layout();
        if(!xs.xPadGlobalInfo.xPadIsActive)revert Paused();
        if(!xs.xPadProject[_id].xPadIsExist)revert Invalid_Input();
        if(xs.xPadUserInfo[msg.sender][_id].userIsXPadRegister)revert User_Already_Registered();
        if(block.timestamp < xs.xPadProject[_id].xPadRegisterStartDate)revert Wait_For_Register_Times();
        if(block.timestamp > xs.xPadProject[_id].xPadRegisterEndDate)revert Wait_For_Register_Times();

        uint256 stakeScore = LibStake.layout().user[msg.sender].userTotalScore;
        if(stakeScore < 1)revert User_Not_Staker();

        xs.xPadUserInfo[msg.sender][_id].userIsXPadRegister = true;
        xs.xPadUserInfo[msg.sender][_id].userXPadScore = stakeScore;

        unchecked {
            xs.xPadProject[_id].xPadTotalScore += stakeScore;
        }

        emit HANDLE_REGISTER_XPAD(msg.sender,_id,block.timestamp);
    }

}