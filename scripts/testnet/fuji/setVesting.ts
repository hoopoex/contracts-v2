import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const PROJECT_ID = 1;
  const VESTING_CONTRACT_ADDRESS = "0x405Ad9243aaCc79957f6F09Ab8E8eEB1A67e8745";
  const DIAMOND_CONTRACT_ADDRESS = "0x6359c238dfA2F67B19BF05580FeF5f31eDd62f06";

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
