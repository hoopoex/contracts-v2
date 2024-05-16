// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { ISolidStateERC20 } from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import { TStakePoolVeriables,TMembership,TNFT,TXPadInfo } from "../libraries/Structs.sol";
import '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { LibMembership } from "../libraries/LibMembership.sol";
import { Modifiers } from "../libraries/Modifiers.sol";
import { LibXPad } from "../libraries/LibXPad.sol";
import { LibStake } from "../libraries/LibStake.sol";
import "../libraries/Errors.sol";

contract Settings is Modifiers,OwnableInternal {

    function addStakeTimes(
        uint256[] memory _times,
        uint256[] memory _multipliers
    ) 
        external 
        onlyOwner 
    {
        uint256[] memory times = _times;
        uint256[] memory multipliers = _multipliers;
        uint256 length = times.length;
        if(length != multipliers.length)revert Array_Lengths_Not_Match();

        LibStake.Layout storage ss = LibStake.layout();
        for (uint256 i = 0; i < length;) {
            ss.timeMultipler[times[i]] = multipliers[i];
            ss.stakeTimes.push(times[i]);

            unchecked {
                i++;
            }
        }
    }

    function setStakePoolVeriables(
        TStakePoolVeriables memory _params
    ) 
        external 
        onlyOwner 
    {
        LibStake.layout().stakePoolVeriables = _params;
    }

    function setStakePoolStatus(
        bool _status
    )
        external 
        onlyOwner 
    {
        LibStake.layout().stakePoolVeriables.isActive = _status;
    }

    function setBlacklist(
        bool _status,
        address _user
    ) 
        external 
        onlyOwner 
    {
        LibStake.layout().user[_user].userIsBlacklist = _status;
    }

    function initMembership(
        TMembership memory _params
    )
        external 
        onlyOwner 
    {
        LibMembership.layout().membership = _params;
    }

    function initMembershipNFTs(
        TNFT[] memory _paramsArray
    )
        public 
        onlyOwner 
    {
        LibMembership.Layout storage ms = LibMembership.layout();
        address nftContract = ms.membership.nftContract;
        uint256[] storage tokenIDs = ms.membership.tokenIDs;
        TNFT[] memory paramsArray = _paramsArray;
        for(uint256 i = 0; i < paramsArray.length;) {
            TNFT memory params = paramsArray[i];
            if(!LibMembership.checkExistence(tokenIDs,params.tokenID))revert Invalid_Action();
            ms.nft[nftContract][params.tokenID] = params;

            unchecked{
                i++;
            }
        }
    }

    function setMembershipActive(
        bool _status
    ) 
        external 
        onlyOwner 
    {
        LibMembership.layout().membership.membershipIsActive = _status;
    }

    function setAcceptableTokenIDForHoopX(
        uint256 _id
    ) 
        external 
        onlyOwner 
    {
        LibMembership.layout().membership.acceptableTokenIdForHoopX = _id;
    }

    function setBalancedOneHoop(
        uint256 _oneHoop
    )
        external 
        onlyOwner 
    {
        LibMembership.layout().membership.balancedOneHoop = _oneHoop;
    }

    function setBuyPrice(
        uint256 _buyPrice
    )
        external 
        onlyOwner 
    {
        LibMembership.layout().membership.buyPrice = _buyPrice;
    }

    function setUpgradePrice(
        uint256 _upgradePrice
    )
        external 
        onlyOwner 
    {
        LibMembership.layout().membership.upgradePrice = _upgradePrice;
    }

    function setBuyNFTBurnPercentage(
        uint256 _buyNFTBurnPercentage
    )
        external 
        onlyOwner 
    {
        LibMembership.layout().membership.buyNFTBurnPercentage = _buyNFTBurnPercentage;
    }

    function setUpgradeNFTBurnPercentage(
        uint256 _upgradeNFTBurnPercentage
    )
        external 
        onlyOwner 
    {
        LibMembership.layout().membership.upgradeNFTBurnPercentage = _upgradeNFTBurnPercentage;
    }

    function setBuyNFTReservePercentage(
        uint256 _buyNFTReservePercentage
    )
        external 
        onlyOwner 
    {
        LibMembership.layout().membership.buyNFTReservePercentage = _buyNFTReservePercentage;
    }

    function setUpgradeNFTReservePercentage(
        uint256 _upgradeNFTReservePercentage
    )
        external 
        onlyOwner 
    {
        LibMembership.layout().membership.upgradeNFTReservePercentage = _upgradeNFTReservePercentage;
    }

    function setHoopXTokenAddress(
        address _hoopXTokenAddress
    )
        external 
        onlyOwner 
        isValidContract(_hoopXTokenAddress)
    {
        LibMembership.layout().membership.hoopXTokenAddress = _hoopXTokenAddress;
    }

    function setHoopTokenAddress(
        address _hoopTokenAddress
    )
        external 
        onlyOwner 
        isValidContract(_hoopTokenAddress)
    {
        LibMembership.layout().membership.hoopTokenAddress = _hoopTokenAddress;
    }

    function setHoopXReserveAddress(
        address _hoopXReserveAddress
    )
        external 
        onlyOwner 
        isValidContract(_hoopXReserveAddress)
    {
        LibMembership.layout().membership.hoopXReserveAddress = _hoopXReserveAddress;
    }

    function setNFT(
        TNFT memory _params
    )
        external 
        onlyOwner 
    {
        LibMembership.layout().nft[LibMembership.layout().membership.nftContract][_params.tokenID] = _params;
    }

    function setAuthorizedUser(
        bool _status,
        address _user
    ) 
        external 
        onlyOwner 
    {
        LibMembership.layout().authorizedUser[_user] = _status;
    }

    function setXPadUsedTokenAddress(
        address _address
    ) 
        external 
        onlyOwner 
    {
        LibXPad.layout().xPadGlobalInfo.xPadUsedTokenAddress = _address;
    }

    function setXPadActive(
        bool _status
    ) 
        external 
        onlyOwner 
    {
        LibXPad.layout().xPadGlobalInfo.xPadIsActive = _status;
    }

    function setXPadVestingContractAddress(
        uint256 _id,
        address _address
    )
        external 
        onlyOwner 
        isValidContract(_address) 
    {
        if(!LibXPad.layout().xPadProject[_id].xPadIsExist)revert Invalid_Action();
        LibXPad.layout().xPadProject[_id].vestingContractAddress = _address;
    }

    function setXPadProject(
        TXPadInfo memory _params
    ) 
        external 
        onlyOwner 
    {
        LibXPad.Layout storage xs = LibXPad.layout();
        if(!xs.xPadProject[_params.xPadProjectId].xPadIsExist)revert Invalid_Action();
        address reserveContract = xs.xPadProject[_params.xPadProjectId].projectReserveContract;

        xs.xPadProject[_params.xPadProjectId] = _params;
        xs.xPadProject[_params.xPadProjectId].projectReserveContract = reserveContract;
    }

}