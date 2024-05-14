// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { TStakePoolInfo, TChangeCountIndex, TUser, TStakePoolVeriables } from "./Structs.sol";
import { ISolidStateERC20 } from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { IHoopNFT } from "../interfaces/IHoopNFT.sol";
import "../libraries/Errors.sol";

library LibStake {
    using Math for uint256;
    using Arrays for uint256[];

    bytes32 internal constant STORAGE_SLOT = keccak256('storage.stake.hoopx.ai');

    function supportUpdateChc(
        address _address
    ) 
        internal 
    {
        uint256 blockTime                      = block.timestamp;
        uint256 currentCHCIndex                = layout().stakePoolInfo.poolLastCHCIndex;
        uint256 nextCHCIndex                   = currentCHCIndex + 1;

        layout().chc[currentCHCIndex].chcEndDate     = blockTime;
        layout().stakePoolInfo.poolLastCHCIndex      = nextCHCIndex;
        layout().user[_address].userChangeCountIndex = nextCHCIndex;

        layout().chc[nextCHCIndex].chcStartDate                   = blockTime;
        layout().chc[nextCHCIndex].chcTotalStakeScore             = layout().stakePoolInfo.poolTotalStakeScore;

        layout().chc[nextCHCIndex].chcToken0RewardPerTime         = layout().stakePoolInfo.poolToken0RewardPerTime;
        layout().chc[nextCHCIndex].chcToken1RewardPerTime         = layout().stakePoolInfo.poolToken1RewardPerTime;

        layout().chc[nextCHCIndex].chcToken0DistributionEndDate   = layout().stakePoolInfo.poolToken0DistributionEndDate;
        layout().chc[nextCHCIndex].chcToken1DistributionEndDate   = layout().stakePoolInfo.poolToken1DistributionEndDate;

        layout().chc[nextCHCIndex].chcCanWinPrizesToken0          = blockTime < layout().chc[nextCHCIndex].chcToken0DistributionEndDate;
        layout().chc[nextCHCIndex].chcCanWinPrizesToken1          = blockTime < layout().chc[nextCHCIndex].chcToken1DistributionEndDate;
    }

    function supportCalculateRewards(
        address _user
    ) 
        internal 
        view 
        returns(uint256,uint256) 
    {
        uint256 token0Reward = 0;
        uint256 token1Reward = 0;
        address user = _user;

        if(layout().user[user].userIsStaker) {
            uint256 userCCIndex = layout().user[user].userChangeCountIndex;
            uint256 poolCCIndex = layout().stakePoolInfo.poolLastCHCIndex;
            uint256 blockTime = block.timestamp;
            uint256 differenceAmount = 1 ether;
            for(uint256 i = userCCIndex; i <= poolCCIndex;) {
                uint256 userWeight = layout().user[user].userTotalScore.mulDiv(differenceAmount,layout().chc[i].chcTotalStakeScore);
                uint256 reward0 = layout().chc[i].chcToken0RewardPerTime.mulDiv(userWeight,differenceAmount);
                uint256 reward1 = layout().chc[i].chcToken1RewardPerTime.mulDiv(userWeight,differenceAmount);

                if(layout().chc[i].chcCanWinPrizesToken0) {
                    uint256 userActiveTimeForToken0 = 0;

                    if(i == poolCCIndex && blockTime > layout().chc[i].chcToken0DistributionEndDate) {
                        unchecked {
                            userActiveTimeForToken0 = layout().chc[i].chcToken0DistributionEndDate - layout().chc[i].chcStartDate;
                        }
                    } else {
                        if(i == poolCCIndex) {
                            unchecked {
                                userActiveTimeForToken0 = blockTime - layout().chc[i].chcStartDate;
                            }
                        } else {
                            unchecked {
                                userActiveTimeForToken0 = layout().chc[i].chcEndDate - layout().chc[i].chcStartDate;
                            }
                        }
                    }
                    unchecked {
                        token0Reward = token0Reward + (reward0 * userActiveTimeForToken0);
                    }
                }

                if(layout().chc[i].chcCanWinPrizesToken1) {
                    uint256 userActiveTimeForToken1 = 0;

                    if(i == poolCCIndex && blockTime > layout().chc[i].chcToken1DistributionEndDate) {
                        unchecked {
                            userActiveTimeForToken1 = layout().chc[i].chcToken1DistributionEndDate - layout().chc[i].chcStartDate;
                        }
                    } else {
                        if(i == poolCCIndex) {
                            unchecked {
                                userActiveTimeForToken1 = blockTime - layout().chc[i].chcStartDate;
                            }
                        } else {
                            unchecked {
                                userActiveTimeForToken1 = layout().chc[i].chcEndDate - layout().chc[i].chcStartDate;
                            }
                        }
                    }
                    unchecked {
                        token1Reward = token1Reward + (reward1 * userActiveTimeForToken1);
                    }
                }
                unchecked {
                    i++;
                }
            }
        }
        return (token0Reward, token1Reward);
    }

    function supportSafeClaim(
        address _user
    ) 
        internal 
    {
        (uint256 token0Reward, uint256 token1Reward) = supportCalculateRewards(_user);
        if(token0Reward > 0) {
            unchecked {
                layout().user[_user].userEarnedToken0Amount += token0Reward;
                layout().stakePoolInfo.poolToken0LiquidityAmount -= token0Reward;
                layout().stakePoolInfo.poolToken0DistributedRewards += token0Reward;
            }
            ISolidStateERC20(layout().stakePoolVeriables.token0ContractAddress).transfer(_user,token0Reward);
        }

        if(token1Reward > 0) {
            unchecked {
                layout().user[_user].userEarnedToken1Amount += token1Reward;
                layout().stakePoolInfo.poolToken1LiquidityAmount -= token1Reward;
                layout().stakePoolInfo.poolToken1DistributedRewards += token1Reward;
            }
            ISolidStateERC20(layout().stakePoolVeriables.token1ContractAddress).transfer(_user,token1Reward);
        }
    }

    function supportCalculateTimeMultipler(
        uint256 _time
    ) 
        internal 
        view 
        returns (uint256) 
    {
        LibStake.Layout storage ss = LibStake.layout();
        uint256[] memory times = ss.stakeTimes;
        uint256 length = times.length;
        for(uint256 i = 0; i < length;) {
            uint256 currentTime = times[i];
            uint256 nextTime = (i < length - 1) ? times[i + 1] : type(uint256).max;

            if (_time >= currentTime && _time < nextTime) {
                return ss.timeMultipler[currentTime];
            }

            unchecked { 
                i++; 
            }
        }
        return 0;
    }

    function supportTransferERC20(
        uint256 _amount,
        address _from,
        address _to,
        address _tokenAddress
    ) 
        internal 
    {
        ISolidStateERC20 token = ISolidStateERC20(_tokenAddress);
        if(token.balanceOf(_from) < _amount)revert Insufficient_Balance();
        if(token.allowance(_from, _to) < _amount)revert Insufficient_Allowance();
        token.transferFrom(_from, _to, _amount);
    }

    function supportTransferERC1155(
        uint256 _tokenId,
        uint256 _amount,
        address _from,
        address _to,
        address _tokenAddress
    ) 
        internal 
    {
        IHoopNFT token = IHoopNFT(_tokenAddress);
        if(token.balanceOf(_from,_tokenId) < 1)revert Insufficient_Balance();
        if(!token.isApprovedForAll(_from, _to))revert Insufficient_Allowance();
        token.safeTransferFrom(_from,_to,_tokenId,_amount,"");
    }

    struct Layout {
        uint256[] stakeTimes;

        mapping(uint256 => uint256) timeMultipler;
        mapping(uint256 => TChangeCountIndex) chc;
        mapping(address => TUser) user;
        
        TStakePoolInfo stakePoolInfo;
        TStakePoolVeriables stakePoolVeriables;
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