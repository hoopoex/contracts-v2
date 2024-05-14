// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { LibMerkleProof } from "../internal/libraries/LibMerkleProof.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Invalid_Input();
error Overflow_0x11();
error Try_Again_Later();
error Invalid_Adder(address);
error Insufficient_Balance();
error Insufficient_Allowance();
error Address_Cannot_Be_Zero();
error Address_Is_A_Not_Contract(address);

contract XPadVesting is Pausable, Ownable, ReentrancyGuard {
    using Math for uint256;

    string private name_;
    bool private isAdding = false;

    struct TVestingPool {
        bytes32 merkleRoot;
        uint256 poolIndex;
        uint256 totalUsers;
        uint256 totalTokensToBeDistributed;
        address tokenAddress;
    }

    struct TPoolUtils {
        uint256 addedTokens;
    }

    struct TUserUtils {
        uint256 userClaimIndex;
        uint256 userClaimedAmount;
    }

    TVestingPool vestingPool;

    mapping(address => bool) private _adder;
    mapping(uint256 => TPoolUtils) private _poolUtils;
    mapping(bytes32 => TUserUtils) private user;

    event HANDLE_ADDED_TOKENS(address indexed addr,uint256 value,uint256 when);
    event HANDLE_CLAIM_TOKENS(address indexed addr,uint256 value,uint256 when);

    constructor(
        string memory _name,
        address _initialOwner
    ) 
        Ownable(_initialOwner) 
    {
        name_ = _name;
        _adder[_initialOwner] = true;
    }

    function initVesting(
        TVestingPool memory _params
    )
        external 
        onlyOwner 
    {
        vestingPool = _params;
    }

    function getName(
    ) 
        public 
        view 
        returns(
            string memory projectName
        ) 
    {
        projectName = name_;
    }

    function getTokenAddress(
    )
        public 
        view 
        returns(
            address token
        ) 
    {
        token = vestingPool.tokenAddress;
    }

    function getMerkleRoot(
    )
        public 
        view 
        returns(
            bytes32 root
        )
    {
        root = vestingPool.merkleRoot;
    }

    function getAdder(
        address _address
    )
        public 
        view 
        returns(
            bool isAdder
        )
    {
        isAdder = _adder[_address];
    }

    function getVestingPool(
    ) 
        public 
        view 
        returns(
            TVestingPool memory poolInfo
        ) 
    {
        poolInfo = vestingPool;
    }

    function getPoolUtils(
        uint256 _index
    )
        public 
        view 
        returns(
            TPoolUtils memory poolUtils
        ) 
    {
        poolUtils = _poolUtils[_index];
    }

    function getAllPoolUtils(
    )
        public 
        view 
        returns(
            TPoolUtils[] memory poolUtils
        ) 
    {
        uint256 length = vestingPool.poolIndex;
        TPoolUtils[] memory utils = new TPoolUtils[](length);
        for(uint256 i = 0; i < length;){
            utils[i] = _poolUtils[i];
            unchecked {
                i++;
            }
        }
        poolUtils = utils;
    }

    function claim(
        uint256 _nodeIndex, 
        uint256 _amount, 
        bytes32[] calldata _merkleProof
    ) 
        external 
        nonReentrant 
        whenNotPaused 
    {
        bytes32 node = keccak256(abi.encodePacked(_nodeIndex, msg.sender, _amount));
        require(LibMerkleProof.verify(_merkleProof, vestingPool.merkleRoot, node), "Invalid proof.");
        if(isAdding)revert Try_Again_Later();
        if(user[node].userClaimIndex == vestingPool.poolIndex)revert Try_Again_Later();

        (
            uint256 claimableAmount
        ) = getClaimableAmount(_nodeIndex,_amount,msg.sender,_merkleProof);
        if(claimableAmount == 0)revert Overflow_0x11();

        unchecked {
            user[node].userClaimedAmount += claimableAmount;
            user[node].userClaimIndex = vestingPool.poolIndex;
        }

        IERC20(vestingPool.tokenAddress).transfer(msg.sender,claimableAmount);
        emit HANDLE_CLAIM_TOKENS(msg.sender,claimableAmount,block.timestamp);
    } 

    function getClaimableAmount(
        uint256 _nodeIndex, 
        uint256 _amount, 
        address _user, 
        bytes32[] calldata _merkleProof
    ) 
        public 
        view 
        returns(uint256 claimableAmount) 
    {
        bytes32 node = keccak256(abi.encodePacked(_nodeIndex, _user, _amount));
        if(!LibMerkleProof.verify(_merkleProof, vestingPool.merkleRoot, node)){ return 0; }
        if(user[node].userClaimedAmount == _amount){ return 0; }
        uint256 exClaimableAmount = 0;
        uint256 exLength = user[node].userClaimIndex;
        for(uint256 i = exLength; i < vestingPool.poolIndex;){
            uint256 a = ((_poolUtils[i].addedTokens * 1 ether) / vestingPool.totalTokensToBeDistributed) * 100;
            uint256 b = (_amount * a) / 100 ether;
            unchecked {
                exClaimableAmount += b;
                i++;
            }
        }

        claimableAmount = exClaimableAmount;
    }

    function getClaimedAmount(
        uint256 _nodeIndex, 
        uint256 _amount, 
        address _user, 
        bytes32[] calldata _merkleProof
    ) 
        public 
        view 
        returns(
            uint256 claimedAmount
        ) 
    {
        bytes32 node = keccak256(abi.encodePacked(_nodeIndex, _user, _amount));
        if(!LibMerkleProof.verify(_merkleProof, vestingPool.merkleRoot, node)){ return 0; }
        claimedAmount = user[node].userClaimedAmount;
    }

    function getUndrawedAmount(
        uint256 _nodeIndex, 
        uint256 _amount, 
        address _user, 
        bytes32[] calldata _merkleProof
    ) 
        public 
        view 
        returns(
            uint256 undrawedAmount
        ) 
    {
        bytes32 node = keccak256(abi.encodePacked(_nodeIndex, _user, _amount));
        if(!LibMerkleProof.verify(_merkleProof, vestingPool.merkleRoot, node)){ return 0; }
        if(user[node].userClaimedAmount == _amount){ return 0; }
        undrawedAmount = _amount - user[node].userClaimedAmount;
    }

    function getUser(
        uint256 _nodeIndex, 
        uint256 _amount, 
        address _user
    ) 
        public 
        view 
        returns(TUserUtils memory userUtils) 
    {
        bytes32 node = keccak256(abi.encodePacked(_nodeIndex, _user, _amount));
        userUtils = user[node];
    }

    function setMerkleRoot(
        bytes32 _merkleRoot
    ) 
        external 
        onlyOwner 
    {
        vestingPool.merkleRoot = _merkleRoot;
    }

    function setAdder(
        bool _status,
        address _newAdder
    )
        external 
        onlyOwner 
    {
        _adder[_newAdder] = _status;
    }

    function addTokens(
        uint256 _amount,
        address _tokenAddr
    ) 
        external 
        adding 
        onlyAdder(msg.sender) 
        isValidContract(_tokenAddr) 
    {
        if(_tokenAddr != vestingPool.tokenAddress)revert Invalid_Input();
        IERC20 token = IERC20(_tokenAddr);
        if(token.balanceOf(msg.sender) < _amount)revert Insufficient_Balance();
        if(token.allowance(msg.sender, address(this)) < _amount)revert Insufficient_Allowance();

        unchecked {
            _poolUtils[vestingPool.poolIndex].addedTokens += _amount;
            vestingPool.poolIndex++;
        }
        
        token.transferFrom(msg.sender, address(this), _amount);
        emit HANDLE_ADDED_TOKENS(_tokenAddr,_amount,block.timestamp);
    }

    function pause(
    ) 
        public 
        onlyOwner 
    {
        _pause();
    }

    function unpause(
    ) 
        public 
        onlyOwner 
    {
        _unpause();
    }

    modifier onlyAdder(
        address _address
    )
    {
        if(!_adder[_address])revert Invalid_Adder(_address);
        _;
    }

    modifier isValidContract(
        address _contractAddress
    )
    {
        if(_contractAddress == address(0))revert Address_Cannot_Be_Zero();
        uint256 size;

        assembly {
            size := extcodesize(_contractAddress)
        }

        bool isContract = size > 0;
        if(!isContract)revert Address_Is_A_Not_Contract(_contractAddress);
        _;
    }

    modifier adding(
    ) 
    {
        isAdding = true;
        _;
        isAdding = false;
    }

    function withdrawToken(
        uint256 _amount,
        address _to,
        address _token
    ) 
        external 
        onlyOwner 
    {
        IERC20 token = IERC20(_token);
        if(token.balanceOf(address(this)) < _amount)revert Insufficient_Balance();
        token.transfer(_to,_amount);
    }

    function withdrawNative(
        address _user
    ) 
        external 
        onlyOwner 
    {
        uint256 amount = address(this).balance;
        if(amount > 0){
            address to = _user;
            (bool success, ) = to.call{value: amount}(new bytes(0));
            require(success);
        }
    }

    receive() external payable {}
}