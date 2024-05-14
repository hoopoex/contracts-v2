// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { TStakePoolInfo,TStakePoolVeriables, TUser,TXPadInfo,TXPadUserInfo,TXPadUserData } from "../libraries/Structs.sol";
import { LibStake } from "../libraries/LibStake.sol";
import { LibXPad } from "../libraries/LibXPad.sol";


contract Query {

    function getStakePoolInfo(
    )
        public 
        view 
        returns(TStakePoolInfo memory info) 
    {
        info = LibStake.layout().stakePoolInfo;
    }
    

    function getStakePoolVeriables(
    )
        public 
        view 
        returns(TStakePoolVeriables memory info) 
    {
        info = LibStake.layout().stakePoolVeriables;
    }


    function getStakerInfo(
        address _user
    )
        public 
        view 
        returns(TUser memory info) 
    {
        info = LibStake.layout().user[_user];
    }


    function getRewards(
        address _user
    )
        public 
        view 
        returns (uint256,uint256) 
    {
        (
            uint256 token0Rewards,
            uint256 token1Rewards
        ) = LibStake.supportCalculateRewards(_user);

        return (token0Rewards,token1Rewards);
    }


    function getStakeInputTotalScore(
        uint256 _amount,
        uint256 _lockTime,
        address _user
    ) 
        public 
        view 
        returns (uint256 totalScore) 
    {
        LibStake.Layout storage ss = LibStake.layout();

        if(!ss.user[_user].userIsStaker){
            uint256 amountScore = _amount / 2;
            uint256 timeMultipler = LibStake.supportCalculateTimeMultipler(_lockTime);
            totalScore = amountScore * (timeMultipler / 1 ether);
        }else{
            uint256 amountScore = (_amount + ss.user[_user].userTotalStakeAmount) / 2;
            totalScore = (amountScore + ss.user[_user].userMembershipScore) * (ss.user[_user].userTimeMultipler / 1 ether);
        }
    }

    function getAllXPadProjects(
    )
        public 
        view 
        returns (TXPadInfo[] memory) 
    {
        LibXPad.Layout storage xs = LibXPad.layout();
        uint256[] memory ids = xs.xPadGlobalInfo.xPadProjectIds;
        uint256 idsLength = ids.length;
        TXPadInfo[] memory projects = new TXPadInfo[](idsLength);

        for (uint256 i = 0; i < idsLength;) {
            projects[i] = xs.xPadProject[ids[i]];

            unchecked{
                i++;
            }
        }
        return projects;
    }

    function getXPad(
        uint256 _id
    )
        public 
        view 
        returns(TXPadInfo memory) 
    {
        return LibXPad.layout().xPadProject[_id];
    }

    function getXPadUser(
        uint256 _id,
        address _address
    )
        public 
        view 
        returns(TXPadUserInfo memory) 
    {
        return LibXPad.layout().xPadUserInfo[_address][_id];
    }

    function getXPadUsers(
        uint256 _id
    ) 
        public 
        view 
        returns (TXPadUserData[] memory) 
    {
        return LibXPad.layout().xPadUserData[_id];
    }
    
}