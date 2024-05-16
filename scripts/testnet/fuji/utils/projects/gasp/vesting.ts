import { ethers } from "hardhat";
import { parseEther } from "viem";

async function main() {
  const [deployer] = await ethers.getSigners();

  const VESTING_ADDRESS = "";
  const Vesting = await ethers.getContractFactory("XPadVesting");
  const vesting = await Vesting.deploy(
    "GASP Vesting Contract",
    deployer.address
  );
  await vesting.deployed();

  const VESTING_PARAMS = {
    merkleRoot:
      "0xd92df866e398241c640e3818e847f990b78108b0fcafe3ab683965ed23f48ef3",
    poolIndex: 0,
    totalUsers: 0,
    totalTokensToBeDistributed: parseEther("20000"),
    tokenAddress: "0xb411eC1ee06144F9bCcE2400a49dAFBfd79dAE19",
  };

  const initVesting = await vesting
    .connect(deployer)
    .initVesting(VESTING_PARAMS);
  await initVesting.wait();

  console.log("Success init 👍 => Merkle Root : ", VESTING_PARAMS.merkleRoot);
  console.log("Vesting Contract => ", vesting.address);
}

/*
npx hardhat run scripts/testnet/fuji/utils/projects/gasp/vesting.ts --network avalanche-fuji
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
