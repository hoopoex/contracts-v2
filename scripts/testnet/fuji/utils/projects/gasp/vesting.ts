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
      "0x192f603e4d4b6621819cc27a32596da63b5b0ccc8cabc59bf85eb39a45c22feb",
    poolIndex: 0,
    totalUsers: 0,
    totalTokensToBeDistributed: parseEther("57440"),
    tokenAddress: "0x7B139A56da96FFef1E5B2183e00EBa74590fe4e0",
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
