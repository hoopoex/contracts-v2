import { ethers } from "hardhat";
import { parseEther } from "viem";

async function main() {
  const [deployer] = await ethers.getSigners();

  const VESTING_ADDRESS = "0x405Ad9243aaCc79957f6F09Ab8E8eEB1A67e8745";
  const TOKEN_ADDRESS = "0xb411eC1ee06144F9bCcE2400a49dAFBfd79dAE19";
  const LIQUIDITY_AMOUNT = parseEther("500");

  const Vesting = await ethers.getContractFactory("XPadVesting");
  const vesting = await Vesting.attach(VESTING_ADDRESS);
  await vesting.deployed();

  const token = await ethers.getContractAt("Hoopoe", TOKEN_ADDRESS);
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
