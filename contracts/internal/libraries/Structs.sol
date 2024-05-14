
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { ItemType } from "./Enums.sol";

struct TStakePoolVeriables {
    bool isActive;

    uint256 minimumStakeAmount;
    uint256 minimumUpdateStakeAmount;

    uint256 minimumLockTime;
    uint256 maximumLockTime;

    address token0ContractAddress;
    address token1ContractAddress;
    address membershipNFTContractAddress;
}

struct TStakePoolInfo {
    uint256 poolLastCHCIndex;
    uint256 poolNumberOfStakers;

    uint256 poolTotalStakedTokens;
    uint256 poolTotalStakeScore;

    uint256 poolToken0RewardPerTime;
    uint256 poolToken0LiquidityAmount;
    uint256 poolToken0DistributedRewards;
    uint256 poolToken0DistributionEndDate;

    uint256 poolToken1RewardPerTime;
    uint256 poolToken1LiquidityAmount;
    uint256 poolToken1DistributedRewards;
    uint256 poolToken1DistributionEndDate;
}

struct TChangeCountIndex{
    bool chcCanWinPrizesToken0;
    bool chcCanWinPrizesToken1;

    uint256 chcTotalStakeScore;
    uint256 chcStartDate;
    uint256 chcEndDate;

    uint256 chcToken0RewardPerTime;
    uint256 chcToken0DistributionEndDate;

    uint256 chcToken1RewardPerTime;
    uint256 chcToken1DistributionEndDate;        
}

struct TUser {
    bool userIsStaker;
    bool userIsNFTStaker;
    bool userIsBlacklist;

    uint256 userChangeCountIndex;
    uint256 userTotalStakeAmount; // 4

    uint256 userMembershipScore;
    uint256 userTotalScore;
    uint256 userTokenScore;
    uint256 userTimeMultipler;

    uint256 userStakeEnterDate;
    uint256 userStakeEndDate;

    uint256 userStakedNFTId;

    uint256 userEarnedToken0Amount;
    uint256 userEarnedToken1Amount;
}

struct TMembership{
    bool membershipIsActive;

    uint256 acceptableTokenIdForHoopX; // 5 = 1,2,3,4,5
    uint256 balancedOneHoop; // 1 HOOP = 70 HOOPX

    uint256 buyPrice; // 0.0012 eth
    uint256 buyNFTBurnPercentage;
    uint256 buyNFTReservePercentage;

    uint256 upgradePrice; // 0.0012 eth
    uint256 upgradeNFTBurnPercentage;
    uint256 upgradeNFTReservePercentage;

    uint256[] tokenIDs;

    address hoopXTokenAddress;
    address hoopTokenAddress;

    address hoopXReserveAddress;

    address nftContract;
}

struct TNFT{
    bool nftIsExist;
    uint256 tokenID;
    uint256 price;
}


struct TXPadGlobalInfo {
    bool xPadIsActive;

    uint256 xPadTotalProjectCount;
    uint256 xPadTotalUserCount;

    uint256[] xPadProjectIds;

    address xPadUsedTokenAddress;
}

struct TXpadSocials {
    string web;
    string twitter;
    string telegram;
    string whitepaper;
}

struct TXPadDetails {
    string slug;
    string name;
    string developer;
    string description;
    string imageLogo;
    string imagePoster;
    string imageBackground;

    TXpadSocials socials;
    string[] genres;
}

struct TXPadInfo {
    bool xPadIsExist;
    bool isView;

    ItemType itemType;

    TXPadDetails xPadDetails;

    uint256 vestingChaindId; // 4
    uint256 xPadProjectId;

    uint256 toBeCollectedValue;
    uint256 collectedValue;

    uint256 minDepositValue;
    uint256 maxDepositValue;

    uint256 tokenPrice; // 10
    uint256 xPadTotalScore;

    uint256 xPadRegisterStartDate;
    uint256 xPadRegisterEndDate;

    uint256 xPadDepositStartDate;
    uint256 xPadDepositEndDate;

    address vestingContractAddress;
    address projectWalletAddress;
    address projectReserveContract;
}

struct TXPadUserData {
    uint256 xPadValue; // user
    uint256 xPadAmount; // user
    address xPadAddress; // user
}

struct TXPadUserInfo {
    bool userIsXPadInvestmentor;
    bool userIsXPadRegister;

    uint256 userXPadScore;
    uint256 userXPadDepositedValue;
}