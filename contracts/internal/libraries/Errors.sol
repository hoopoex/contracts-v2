// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @dev Revert with an error when an account being called as an assumed
 *      contract does not have code and returns no data.
 * @param account The account that should contain code.
 */
  error Address_Is_A_Contract(address account);
  error Address_Is_A_Not_Contract(address account);
  error Address_Cannot_Be_Zero(address account);
  error Address_In_Blacklist(address account);

  error Array_Lengths_Not_Match();
  
  error Insufficient_Balance();
  error Insufficient_Allowance();
  error Insufficient_Lock_Time();
  error Insufficient_Stake_Amount();
  error Insufficient_Deposit_Time();

  error Paused();
  error Sale_End();

  error Overflow_0x11();
  error Invalid_Price();
  error Invalid_Input();
  error Invalid_Proof();
  error Invalid_Action();
  error Invalid_Address();

  error User_Is_Member();
  error User_Is_Staker();
  error Not_Authorized();
  error User_Not_Staker();
  error User_Not_Expired();
  error User_Not_Register();
  error User_Already_Staked();
  error User_Already_Claimed();
  error User_Already_Registered();

  error Wait_For_Deposit_Times();
  error Wait_For_Register_Times();
  