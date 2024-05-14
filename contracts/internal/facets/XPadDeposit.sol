// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { ISolidStateERC20 } from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import  "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { TXPadUserData } from "../libraries/Structs.sol";
import { Modifiers } from "../libraries/Modifiers.sol";
import { LibStake } from "../libraries/LibStake.sol";
import { LibXPad } from "../libraries/LibXPad.sol";

import "../libraries/Errors.sol";

contract XPadDeposit is Modifiers, ReentrancyGuard {
    using Math for uint256;

    event HANDLE_XPAD_DEPOSIT(address indexed addr,uint256 id,uint256 when);


    function xPadDeposit(
        uint256 _id,
        uint256 _amount
    ) 
        external 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        LibXPad.Layout storage xs = LibXPad.layout();
        uint256 blocktime = block.timestamp;
        uint256 projectId = _id;
        uint256 amount = _amount;
        if(!xs.xPadProject[projectId].xPadIsExist)revert Invalid_Action();
        if(!xs.xPadGlobalInfo.xPadIsActive)revert Paused();
        if(!xs.xPadUserInfo[msg.sender][projectId].userIsXPadRegister)revert User_Not_Register();
        if(xs.xPadUserInfo[msg.sender][projectId].userIsXPadInvestmentor)revert User_Not_Expired();
        if(blocktime > xs.xPadProject[projectId].xPadDepositEndDate)revert Insufficient_Deposit_Time();
        if(blocktime < xs.xPadProject[projectId].xPadDepositStartDate)revert Insufficient_Deposit_Time();
        if(amount < xs.xPadProject[projectId].minDepositValue)revert Invalid_Price();
        if(amount > xs.xPadProject[projectId].maxDepositValue)revert Invalid_Price();
        if(xs.xPadProject[projectId].toBeCollectedValue == xs.xPadProject[projectId].collectedValue)revert Sale_End();

        uint256 remainingAmount = xs.xPadProject[projectId].toBeCollectedValue - xs.xPadProject[projectId].collectedValue;
        if(amount > remainingAmount)revert Overflow_0x11();
        (uint256 usdAllocation, ) = xPadCalculateUserAllocations(projectId,msg.sender);
        if(amount > usdAllocation)revert Overflow_0x11();

        xs.xPadUserInfo[msg.sender][projectId].userIsXPadInvestmentor = true;
        uint256 allocationTokenAmount = (amount * 1 ether) / xs.xPadProject[_id].tokenPrice;

        unchecked {
            xs.xPadGlobalInfo.xPadTotalUserCount++;
            xs.xPadProject[projectId].collectedValue += amount;
            xs.xPadUserInfo[msg.sender][projectId].userXPadDepositedValue = amount;
        }

        _supportStoreUserData(projectId,amount,allocationTokenAmount,msg.sender);
        LibStake.supportTransferERC20(amount,msg.sender,address(this),xs.xPadGlobalInfo.xPadUsedTokenAddress);
        ISolidStateERC20(xs.xPadGlobalInfo.xPadUsedTokenAddress).transfer(xs.xPadProject[projectId].projectReserveContract,amount);

        emit HANDLE_XPAD_DEPOSIT(msg.sender,projectId,blocktime);
    }

    function _supportStoreUserData(
        uint256 _id,
        uint256 value,
        uint256 _amount,
        address _address
    ) 
        private 
    {
        TXPadUserData memory newUser;
        newUser.xPadValue = value;
        newUser.xPadAmount = _amount;
        newUser.xPadAddress = _address;
        LibXPad.layout().xPadUserData[_id].push(newUser);
    }

    function xPadCalculateUserAllocations(
        uint256 _id,
        address _user
    ) 
        public 
        view 
        returns (
            uint256 usdAllocation,
            uint256 tokenAllocation
        ) 
    {
        LibXPad.Layout storage xs = LibXPad.layout();
        if (
            block.timestamp < xs.xPadProject[_id].xPadDepositEndDate && 
            block.timestamp > xs.xPadProject[_id].xPadDepositStartDate && 
            !xs.xPadUserInfo[_user][_id].userIsXPadInvestmentor
        ) {
            uint256 decimals = (10 ** ISolidStateERC20(xs.xPadGlobalInfo.xPadUsedTokenAddress).decimals());
            uint256 weight = xs.xPadUserInfo[_user][_id].userXPadScore.mulDiv(decimals,xs.xPadProject[_id].xPadTotalScore);
            uint256 allocationUsdAmount = weight.mulDiv(xs.xPadProject[_id].toBeCollectedValue,decimals);
            uint256 allocationTokenAmount = (allocationUsdAmount / xs.xPadProject[_id].tokenPrice) / decimals;
            usdAllocation = allocationUsdAmount;
            tokenAllocation = allocationTokenAmount;
        }
    }

}