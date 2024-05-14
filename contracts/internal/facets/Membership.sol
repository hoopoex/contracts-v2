// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import  "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { LibMembership } from "../libraries/LibMembership.sol";
import { TMembership } from "../libraries/Structs.sol";
import { Modifiers } from "../libraries/Modifiers.sol";
import { IHoopNFT } from "../interfaces/IHoopNFT.sol";
import { LibStake } from "../libraries/LibStake.sol";
import { IHoopx } from "../interfaces/IHoopx.sol";
import "../libraries/Errors.sol";

contract Membership is Modifiers, ReentrancyGuard {
    using Math for uint256;

    event HANDLE_NFT_BUY_PROCESS(address indexed addr_,uint256 id_,uint256 when_);
    event HANDLE_NFT_UPGRADING_PROCESS(address indexed addr_,uint256 oldid_, uint256 id_, uint256 when_);
    event HANDLE_NFT_MINT_PROCESS(address indexed addr_,uint256 id_,uint256 when_);

    function buyNFT(
        uint256 _tokenID
    ) 
        external 
        payable 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        LibMembership.Layout storage ms = LibMembership.layout();
        if(msg.value != ms.membership.buyPrice)revert Invalid_Price();
        payable(ms.membership.hoopXReserveAddress).transfer(msg.value);
        if(!ms.membership.membershipIsActive)revert Paused();
        address user = msg.sender;
        uint256 tokenID = _tokenID;
        if(!LibMembership.checkExistence(ms.membership.tokenIDs,tokenID))revert Invalid_Action();
        if(checkMember(user))revert User_Is_Member();
        address tokenContract = tokenID > ms.membership.acceptableTokenIdForHoopX ? ms.membership.hoopTokenAddress : ms.membership.hoopXTokenAddress;
        if(tokenContract == address(0)){
            revert Invalid_Action();
        }else{
            _transferAssetsUpdates(false,ms.nft[ms.membership.nftContract][tokenID].price,user,tokenContract);
        }
       
        IHoopNFT(ms.membership.nftContract).mint(user,tokenID,1,"");
        
        emit HANDLE_NFT_BUY_PROCESS(user,tokenID,block.timestamp);
    }

    function upgradeNFT(
        uint256 _tokenID, 
        uint256 _upTokenID
    ) 
        external 
        payable 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        LibMembership.Layout storage ms = LibMembership.layout();
        if(msg.value != ms.membership.upgradePrice)revert Invalid_Price();
        payable(ms.membership.hoopXReserveAddress).transfer(msg.value);
        IHoopNFT nft = IHoopNFT(ms.membership.nftContract);
        address user = msg.sender;

        if(LibStake.layout().user[user].userIsStaker)revert User_Is_Staker();
        if(_tokenID > _upTokenID)revert Invalid_Action();
        if(!ms.membership.membershipIsActive)revert Paused();
        if(!LibMembership.checkExistence(ms.membership.tokenIDs,_tokenID))revert Invalid_Action();
        if(!LibMembership.checkExistence(ms.membership.tokenIDs,_upTokenID))revert Invalid_Action();
        
        if(nft.balanceOf(user, _tokenID) == 0)revert Insufficient_Balance();
        if(!nft.isApprovedForAll(user, address(this)))revert Insufficient_Allowance();

        uint256 tokenPrice = ms.nft[ms.membership.nftContract][_tokenID].price;
        uint256 upgradeTokenPrice = ms.nft[ms.membership.nftContract][_upTokenID].price;
        address tokenContract = _upTokenID > ms.membership.acceptableTokenIdForHoopX ? ms.membership.hoopTokenAddress : ms.membership.hoopXTokenAddress;

        if(tokenContract == address(0)) {
            revert Invalid_Action(); 
        }else if(tokenContract == ms.membership.hoopTokenAddress) {
            uint256 hoopRemainingAmount = 0;
            if(_tokenID <= ms.membership.acceptableTokenIdForHoopX) {
                uint256 hoopxConvertedPrice = _convertToDisplay(tokenPrice,ms.membership.hoopXTokenAddress);
                (bool success0,uint256 hoopRemainingAmountOne) = hoopxConvertedPrice.tryDiv(ms.membership.balancedOneHoop);
                if(!success0)revert Overflow_0x11();
                (bool success1,uint256 hoopRemainingAmountTwo) = hoopRemainingAmountOne.tryMul(10 ** IHoopx(ms.membership.hoopTokenAddress).decimals());
                if(!success1)revert Overflow_0x11();
                hoopRemainingAmount = upgradeTokenPrice - hoopRemainingAmountTwo;
            }else{
                hoopRemainingAmount = upgradeTokenPrice - tokenPrice;
            }
            _transferAssetsUpdates(true,hoopRemainingAmount,user,tokenContract);
        }else{
            uint256 hoopXremainingAmount = upgradeTokenPrice - tokenPrice;
            _transferAssetsUpdates(true,hoopXremainingAmount,user,tokenContract);
        }
       
        nft.burn(user,_tokenID,1);
        nft.mint(user,_upTokenID,1,"");
        emit HANDLE_NFT_UPGRADING_PROCESS(user,_tokenID,_upTokenID,block.timestamp);
    }

    function checkMember(
        address _user
    ) 
        public 
        view 
        returns(bool) 
    {
        LibMembership.Layout storage ms = LibMembership.layout();
        IHoopNFT nft = IHoopNFT(ms.membership.nftContract);
        uint256[] memory tokenIDs = ms.membership.tokenIDs;
        uint256 idsLength = tokenIDs.length;

        if(LibStake.layout().user[_user].userIsNFTStaker) {
            return true;
        }else {
            for (uint256 i = 0; i < idsLength;) {
                bool member = false;
                unchecked { 
                    member = nft.balanceOf(_user,tokenIDs[i]) > 0;
                }
                if (member) {
                    return true;
                }
                unchecked {
                    i++;
                }
            }
        }
        return false;
    }

    function _convertToDisplay(
        uint256 _amount, 
        address _address
    ) 
        internal 
        view 
        returns(uint256 result) 
    {
        result = _amount / (10 ** IHoopx(_address).decimals());
    }

    function _transferAssetsUpdates(
        bool _isUpgrade,
        uint256 _amount,
        address _user,
        address _token
    ) 
        private 
    {
        IHoopx token = IHoopx(_token);
        if(token.balanceOf(_user) < _amount){ revert Insufficient_Balance(); }
        if(token.allowance(_user, address(this)) < _amount){ revert Insufficient_Allowance(); }

        LibMembership.Layout storage ms = LibMembership.layout();
        uint256 burnAmount = 0;
        uint256 reserveAmount = 0;

        if(!_isUpgrade){
            burnAmount = _amount.mulDiv(ms.membership.buyNFTBurnPercentage,100);
            reserveAmount = _amount.mulDiv(ms.membership.buyNFTReservePercentage,100);
        }else{
            burnAmount = _amount.mulDiv(ms.membership.upgradeNFTBurnPercentage,100);
            reserveAmount = _amount.mulDiv(ms.membership.upgradeNFTReservePercentage,100);
        }
        
        token.burnFrom(_user,burnAmount);
        token.transferFrom(_user,ms.membership.hoopXReserveAddress,reserveAmount);
    }

    function authorizedUserMintNFT(
        uint256 _tokenID,
        address _to
    ) 
        external 
        OnlyAuthorizedUser(msg.sender) 
        whenNotContract(msg.sender) 
        nonReentrant 
    {
        LibMembership.Layout storage ms = LibMembership.layout();
        if(!ms.membership.membershipIsActive){ revert Paused(); }
        if(!LibMembership.checkExistence(ms.membership.tokenIDs,_tokenID)){ revert Invalid_Action(); }
        if(checkMember(_to)){ revert User_Is_Member(); }
        IHoopNFT(ms.membership.nftContract).mint(_to,_tokenID,1,"");
        emit HANDLE_NFT_MINT_PROCESS(_to,_tokenID,block.timestamp);
    }

     function getOwnedNFTs(
        address _user
    ) 
        public 
        view 
        returns(uint256[] memory) 
    {
        LibMembership.Layout storage ms = LibMembership.layout();
        uint256[] memory tokenIDs = ms.membership.tokenIDs;
        uint256 tokenIDLengths = tokenIDs.length;
        uint256[] memory ownedNFTs = new uint256[](tokenIDLengths);
        IHoopNFT nft = IHoopNFT(ms.membership.nftContract); 

        uint256 count = 0;
        for (uint256 i = 0; i < tokenIDLengths;){
            if (nft.balanceOf(_user, tokenIDs[i]) > 0){
                ownedNFTs[count] = tokenIDs[i];
                unchecked {
                    count++;
                }
            }
            unchecked {
                i++;
            }
        }
        uint256[] memory result = new uint256[](count);

        for (uint256 j = 0; j < count;){
            result[j] = ownedNFTs[j];

            unchecked {
                j++;
            }
        }
        return result;
    }

    function getMembership(
    ) 
        public 
        view 
        returns(TMembership memory membership) 
    {
        membership = LibMembership.layout().membership;
    }

    function getAuthorizedUser(
        address _user
    ) 
        public 
        view 
        returns(bool authorized) 
    {
        authorized = LibMembership.layout().authorizedUser[_user];
    }

}