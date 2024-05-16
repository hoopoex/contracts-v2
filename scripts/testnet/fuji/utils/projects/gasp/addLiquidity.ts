import { ethers } from "hardhat";
import { parseEther } from "viem";

async function main() {
  const [deployer] = await ethers.getSigners();

  const VESTING_ADDRESS = "0x84Ef283E649d8b5E69dBC4c56cd188DaB1320eAf";
  const TOKEN_ADDRESS = "0x7B139A56da96FFef1E5B2183e00EBa74590fe4e0";
  const LIQUIDITY_AMOUNT = parseEther("10000");

  const Vesting = await ethers.getContractFactory("XPadVesting");
  const vesting = await Vesting.attach(VESTING_ADDRESS);
  await vesting.deployed();

  const token = await ethers.getContractAt("HoopoeTest", TOKEN_ADDRESS);
  await token.deployed();

  const approveTx = await token
    .connect(deployer)
    .approve(vesting.address, LIQUIDITY_AMOUNT);
  await approveTx.wait();

  const addLiquidity = await vesting
    .connect(deployer)
    .addTokens(LIQUIDITY_AMOUNT, TOKEN_ADDRESS);
  await addLiquidity.wait();

  console.log("Success => ", addLiquidity.hash);
  console.log("Vesting Contract => ", vesting.address);
}

/*
npx hardhat run scripts/testnet/fuji/utils/projects/gasp/addLiquidity.ts --network avalanche-fuji
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
