import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const PROJECT_ID = 1;
  const VESTING_CONTRACT_ADDRESS = "0x84Ef283E649d8b5E69dBC4c56cd188DaB1320eAf";
  const DIAMOND_CONTRACT_ADDRESS = "0xD411F6647de6D12ae6476fF531d821d025D63500";

  const createFacetContract = await ethers.getContractAt(
    "Settings",
    DIAMOND_CONTRACT_ADDRESS
  );
  await createFacetContract.deployed();

  const setVesting = await createFacetContract
    .connect(deployer)
    .setXPadVestingContractAddress(PROJECT_ID, VESTING_CONTRACT_ADDRESS);
  await setVesting.wait();

  console.log("Success 👍 ", PROJECT_ID, VESTING_CONTRACT_ADDRESS);
}

/*
npx hardhat run scripts/testnet/fuji/setVesting.ts --network avalanche-fuji
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
