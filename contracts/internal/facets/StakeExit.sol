// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { ISolidStateERC20 } from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import  "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { LibMembership } from "../libraries/LibMembership.sol";
import { Modifiers } from "../libraries/Modifiers.sol";
import { IHoopNFT } from "../interfaces/IHoopNFT.sol";
import { LibStake } from "../libraries/LibStake.sol";
import { TUser } from "../libraries/Structs.sol";
import "../libraries/Errors.sol";

contract StakeExit is Modifiers, ReentrancyGuard {

    event HANDLE_UNSTAKE(address indexed addr,uint256 when);
    event HANDLE_UNSTAKE_NFT(address indexed addr,uint256 id, uint256 when);


    function unstake(
    ) 
        external 
        whenNotContract(msg.sender) 
        nonReentrant 
    {
        LibStake.Layout storage ss = LibStake.layout();

        if(!ss.stakePoolVeriables.isActive)revert Paused();
        if(!ss.user[msg.sender].userIsStaker)revert User_Not_Staker();
        if(ss.user[msg.sender].userIsBlacklist)revert Address_In_Blacklist(msg.sender);
        if(ss.user[msg.sender].userStakeEndDate >= block.timestamp)revert User_Not_Expired();

        uint256 stakedNFTId = ss.user[msg.sender].userStakedNFTId;
        uint256 totalStakedAmount = ss.user[msg.sender].userTotalStakeAmount;

        LibStake.supportSafeClaim(msg.sender);
        _supportUnstakeUpdate(msg.sender);
        
        if(stakedNFTId > 0) {
            IHoopNFT(ss.stakePoolVeriables.membershipNFTContractAddress).safeTransferFrom(address(this),msg.sender,stakedNFTId,1,"");
        }
        ISolidStateERC20(ss.stakePoolVeriables.token0ContractAddress).transfer(msg.sender,totalStakedAmount);

        emit HANDLE_UNSTAKE(msg.sender,block.timestamp);
    }


    function _supportUnstakeUpdate(
        address _user
    ) 
        private 
    {
        LibStake.Layout storage ss = LibStake.layout();

        unchecked {
            ss.stakePoolInfo.poolTotalStakedTokens -= ss.user[_user].userTotalStakeAmount;
            ss.stakePoolInfo.poolTotalStakeScore   -= ss.user[_user].userTotalScore;
            ss.stakePoolInfo.poolNumberOfStakers   -= 1;
        }

        ss.user[_user] = TUser({
            userIsStaker           : false,
            userIsNFTStaker        : false,
            userIsBlacklist        : ss.user[_user].userIsBlacklist,
            userChangeCountIndex   : 0,
            userTotalStakeAmount   : 0,
            userMembershipScore    : 0,
            userTotalScore         : 0,
            userTokenScore         : 0,
            userTimeMultipler      : 0,
            userStakeEnterDate     : 0,
            userStakeEndDate       : 0,
            userStakedNFTId        : 0,
            userEarnedToken0Amount : ss.user[_user].userEarnedToken0Amount,
            userEarnedToken1Amount : ss.user[_user].userEarnedToken1Amount
        });

        LibStake.supportUpdateChc(address(0));
    }


    function unstakeNFT(
    ) 
        external 
        whenNotContract(msg.sender) 
        nonReentrant 
    {
        LibStake.Layout storage ss = LibStake.layout();

        if(!ss.stakePoolVeriables.isActive)revert Paused();
        if(!ss.user[msg.sender].userIsNFTStaker)revert User_Not_Staker();
        if(ss.user[msg.sender].userIsBlacklist)revert Address_In_Blacklist(msg.sender);

        uint256 tokenId = ss.user[msg.sender].userStakedNFTId;

        LibStake.supportSafeClaim(msg.sender);
        _supportUnstakeNFTUpdate(msg.sender);
        LibStake.supportUpdateChc(address(0));
        
        IHoopNFT(ss.stakePoolVeriables.membershipNFTContractAddress).safeTransferFrom(address(this),msg.sender,tokenId,1,"");
        
        emit HANDLE_UNSTAKE_NFT(msg.sender,tokenId,block.timestamp);
    }


    function _supportUnstakeNFTUpdate(
        address _user
    ) 
        private 
    {
        LibStake.Layout storage ss = LibStake.layout();

        uint256 amountScore = ss.user[_user].userTokenScore;
        uint256 totalScore = amountScore * (ss.user[_user].userTimeMultipler / 1 ether);

        unchecked {
            ss.stakePoolInfo.poolTotalStakeScore -= ss.user[_user].userTotalScore;
            ss.stakePoolInfo.poolTotalStakeScore += totalScore;
        }

        ss.user[_user].userIsNFTStaker = false;
        ss.user[_user].userMembershipScore = 0;
        ss.user[_user].userTotalScore = totalScore;
        ss.user[_user].userStakedNFTId = 0;

        LibStake.supportUpdateChc(_user);
    }

}