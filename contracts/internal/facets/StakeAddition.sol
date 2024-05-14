// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import  "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { LibMembership } from "../libraries/LibMembership.sol";
import { Modifiers } from "../libraries/Modifiers.sol";
import { IHoopNFT } from "../interfaces/IHoopNFT.sol";
import { LibStake } from "../libraries/LibStake.sol";
import "../libraries/Errors.sol";

contract StakeAddition is Modifiers, ReentrancyGuard, OwnableInternal {

    event HANDLE_STAKE_ADDITION(address indexed addr,uint256 when);
    event HANDLE_CLAIM_REWARDS(address indexed addr,uint256 when);
    event HANDLE_ADD_LIQUIDITY(address indexed addr,uint256 when);
    event HANDLE_ADD_NFT(address indexed addr,uint256 id,uint256 when);

    
    function stakeAddition(
        uint256 _amount
    ) 
        external 
        whenNotContract(msg.sender) 
        nonReentrant 
    {
        LibStake.Layout storage ss = LibStake.layout();

        if(!ss.stakePoolVeriables.isActive)revert Paused();
        if(!ss.user[msg.sender].userIsStaker)revert User_Not_Staker();
        if(ss.user[msg.sender].userIsBlacklist)revert Address_In_Blacklist(msg.sender);
        if(_amount < ss.stakePoolVeriables.minimumUpdateStakeAmount)revert Insufficient_Stake_Amount();

        LibStake.supportSafeClaim(msg.sender);
        
        _supportStakeAdditionUpdate(_amount,msg.sender);
        LibStake.supportTransferERC20(_amount,msg.sender,address(this),ss.stakePoolVeriables.token0ContractAddress);

        emit HANDLE_STAKE_ADDITION(msg.sender,block.timestamp);
    }


    function _supportStakeAdditionUpdate(
        uint256 _amount,
        address _user
    )
        private 
    {
        LibStake.Layout storage ss = LibStake.layout();
        uint256 amountScore = (_amount + ss.user[_user].userTotalStakeAmount) / 2;
        uint256 totalScore = (amountScore + ss.user[_user].userMembershipScore) * (ss.user[_user].userTimeMultipler / 1 ether);

        unchecked {
            ss.stakePoolInfo.poolTotalStakeScore -= ss.user[_user].userTotalScore;
            ss.stakePoolInfo.poolTotalStakeScore += totalScore;
            ss.stakePoolInfo.poolTotalStakedTokens += _amount;
            ss.user[_user].userTotalStakeAmount += _amount;
        }
        ss.user[_user].userTokenScore = amountScore;
        ss.user[_user].userTotalScore = totalScore;

        LibStake.supportUpdateChc(_user);
    }


    function claimRewards(
    ) 
        external 
        whenNotContract(msg.sender) 
        nonReentrant 
    {
        LibStake.Layout storage ss = LibStake.layout();

        if(!ss.stakePoolVeriables.isActive)revert Paused();
        if(!ss.user[msg.sender].userIsStaker)revert User_Not_Staker();
        if(ss.user[msg.sender].userIsBlacklist)revert Address_In_Blacklist(msg.sender);

        LibStake.supportSafeClaim(msg.sender);
        LibStake.supportUpdateChc(msg.sender);

        emit HANDLE_CLAIM_REWARDS(msg.sender,block.timestamp);
    }


    function addNFT(
        uint256 _tokenId
    ) 
        external 
        whenNotContract(msg.sender) 
        nonReentrant 
    {
        LibStake.Layout storage ss = LibStake.layout();

        if(!ss.stakePoolVeriables.isActive)revert Paused();
        if(!ss.user[msg.sender].userIsStaker)revert User_Not_Staker();
        if(ss.user[msg.sender].userIsNFTStaker)revert User_Already_Staked();
        if(ss.user[msg.sender].userIsBlacklist)revert Address_In_Blacklist(msg.sender);
        if(!LibMembership.checkExistence(LibMembership.layout().membership.tokenIDs,_tokenId))revert Invalid_Action();

        LibStake.supportSafeClaim(msg.sender);

        _supportAddingNFTUpdate(_tokenId,msg.sender);
        LibStake.supportTransferERC1155(_tokenId,1,msg.sender,address(this),ss.stakePoolVeriables.membershipNFTContractAddress);

        emit HANDLE_ADD_NFT(msg.sender,_tokenId,block.timestamp);
    }


    function _supportAddingNFTUpdate(
        uint256 _tokenId,
        address _user
    )
        private 
    {
        LibStake.Layout storage ss = LibStake.layout();

        uint256 amountScore = ss.user[_user].userTokenScore;
        uint256 timeMultipler = ss.user[_user].userTimeMultipler;
        uint256 membershipScore = (IHoopNFT(ss.stakePoolVeriables.membershipNFTContractAddress).getTokenInfo(_tokenId).multiplier * 1 ether);
        uint256 totalScore = (amountScore + membershipScore) * (timeMultipler / 1 ether);

        unchecked {
            ss.stakePoolInfo.poolTotalStakeScore -= ss.user[_user].userTotalScore;
            ss.stakePoolInfo.poolTotalStakeScore += totalScore;
        }
        
        ss.user[_user].userIsNFTStaker = true;
        ss.user[_user].userMembershipScore = membershipScore;
        ss.user[_user].userTotalScore = totalScore;
        ss.user[_user].userStakedNFTId = _tokenId;
        
        LibStake.supportUpdateChc(_user);
    }


    function addLiquidity(
        uint256 _amount,
        address _tokenAddress
    ) 
        external 
        onlyOwner 
        isValidContract(_tokenAddress) 
    {
        LibStake.Layout storage ss = LibStake.layout();

        address token0 = ss.stakePoolVeriables.token0ContractAddress;
        address token1 = ss.stakePoolVeriables.token1ContractAddress;

        if (_tokenAddress == token0) {
            unchecked {
                ss.stakePoolInfo.poolToken0LiquidityAmount += _amount;
                ss.stakePoolInfo.poolToken0RewardPerTime = _amount / 365 days;
                ss.stakePoolInfo.poolToken0DistributionEndDate = block.timestamp + 365 days;
            }
        } else if (_tokenAddress == token1) {
            unchecked {
                ss.stakePoolInfo.poolToken1LiquidityAmount += _amount;
                ss.stakePoolInfo.poolToken1RewardPerTime = _amount / 365 days;
                ss.stakePoolInfo.poolToken1DistributionEndDate = block.timestamp + 365 days;
            }
        } else {
            revert Invalid_Address();
        }

        LibStake.supportTransferERC20(_amount,msg.sender,address(this),_tokenAddress);
        LibStake.supportUpdateChc(address(0));

        emit HANDLE_ADD_LIQUIDITY(msg.sender,block.timestamp);
    }


    function onERC1155Received(
        address, 
        address, 
        uint256, 
        uint256, 
        bytes memory
    ) 
        public 
        virtual 
        returns(bytes4) 
    {
        return this.onERC1155Received.selector;
    }


    function onERC1155BatchReceived(
        address, 
        address, 
        uint256[] memory, 
        uint256[] memory, 
        bytes memory
    ) 
        public 
        virtual 
        returns(bytes4) 
    {
        return this.onERC1155BatchReceived.selector;
    }

}