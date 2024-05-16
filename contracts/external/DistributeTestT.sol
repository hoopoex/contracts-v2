// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error User_Not_Expired(address);
error Insufficient_Balance();

contract DistributeTestT is Ownable, ReentrancyGuard {

    struct TDist {
        uint256 distTokenAmount0;
        uint256 distTokenAmount1;
        uint256 distNativeAmount;
        address distTokenAddr0;
        address distTokenAddr1;
    }
    TDist dist;

    mapping(address => bool) private isClaimed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdrawal(address indexed from, address indexed to, uint256 value);
    event HANDLE_CLAIMS(address indexed to,uint256 token,uint256 native,uint256 when);

    constructor(
        TDist memory _params,
        address _initialOwner
    ) 
        Ownable(_initialOwner) 
    {
        dist = _params;
    }

    function claims(
    ) 
        public 
        nonReentrant 
    {
        uint256 contractNativeBalance = address(this).balance;
        address to = msg.sender;
        if(isClaimed[to])revert User_Not_Expired(to);
        if(contractNativeBalance < dist.distNativeAmount)revert Insufficient_Balance();
        if(IERC20(dist.distTokenAddr0).balanceOf(address(this)) < dist.distTokenAmount0)revert Insufficient_Balance();
        if(IERC20(dist.distTokenAddr1).balanceOf(address(this)) < dist.distTokenAmount1)revert Insufficient_Balance();


        isClaimed[to] = true;

        (bool success, ) = to.call{value: dist.distNativeAmount}(new bytes(0));
        require(success);

        IERC20(dist.distTokenAddr0).transfer(to,dist.distTokenAmount0);
        IERC20(dist.distTokenAddr1).transfer(to,dist.distTokenAmount1);

        emit Transfer(address(this),to,dist.distTokenAmount0);
    }

    function getIsClaimed(
        address _user
    )
        public 
        view 
        returns(bool claimed) 
    {
        claimed = isClaimed[_user];
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
        if(token.balanceOf(address(this)) < _amount){revert Insufficient_Balance();}
        token.transfer(_to,_amount);
        emit Transfer(address(this),_to,_amount);
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
        }else {
            revert Insufficient_Balance();
        }
    }

    receive() external payable {}
}