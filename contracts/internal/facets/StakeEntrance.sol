// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import  "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { Modifiers } from "../libraries/Modifiers.sol";
import { LibStake } from "../libraries/LibStake.sol";
import { TUser } from "../libraries/Structs.sol";
import "../libraries/Errors.sol";

contract StakeEntrance is Modifiers, ReentrancyGuard {

    event HANDLE_STAKE_ENTRANCE(address indexed addr,uint256 when);

    function stakeEntrance(
        uint256 _amount,
        uint256 _lockTime
    ) 
        external 
        whenNotContract(msg.sender) 
        nonReentrant 
    {
        LibStake.Layout storage ss = LibStake.layout();

        if(!ss.stakePoolVeriables.isActive)revert Paused();
        if(ss.user[msg.sender].userIsStaker)revert User_Already_Staked();
        if(ss.user[msg.sender].userIsBlacklist)revert Address_In_Blacklist(msg.sender);
        if(_amount < ss.stakePoolVeriables.minimumStakeAmount)revert Insufficient_Stake_Amount();
        if(_lockTime < ss.stakePoolVeriables.minimumLockTime || _lockTime > ss.stakePoolVeriables.maximumLockTime)revert Insufficient_Lock_Time();

        _supportStakeEntranceUpdate(_amount,_lockTime,msg.sender);
        LibStake.supportTransferERC20(_amount,msg.sender,address(this),ss.stakePoolVeriables.token0ContractAddress);

        emit HANDLE_STAKE_ENTRANCE(msg.sender,block.timestamp);
    }

    function _supportStakeEntranceUpdate(
        uint256 _amount,
        uint256 _lockTime,
        address _user
    )
        private 
    {
        LibStake.Layout storage ss = LibStake.layout();

        uint256 amountScore = _amount / 2;
        uint256 timeMultipler = LibStake.supportCalculateTimeMultipler(_lockTime);
        uint256 totalScore = amountScore * (timeMultipler / 1 ether);

        unchecked {
            ss.stakePoolInfo.poolTotalStakeScore += totalScore;
            ss.stakePoolInfo.poolNumberOfStakers++;
            ss.stakePoolInfo.poolTotalStakedTokens += _amount;
        }

        ss.user[_user] = TUser({
            userIsStaker           : true,
            userIsNFTStaker        : false,
            userIsBlacklist        : false,
            userChangeCountIndex   : 0,
            userTotalStakeAmount   : _amount,
            userMembershipScore    : 0,
            userTotalScore         : totalScore,
            userTokenScore         : amountScore,
            userTimeMultipler      : timeMultipler,
            userStakeEnterDate     : block.timestamp,
            userStakeEndDate       : block.timestamp + _lockTime,
            userStakedNFTId        : 0,
            userEarnedToken0Amount : ss.user[_user].userEarnedToken0Amount,
            userEarnedToken1Amount : ss.user[_user].userEarnedToken1Amount
        });

        LibStake.supportUpdateChc(_user);
    }

}