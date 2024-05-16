import { ethers } from "hardhat";
const { TXPad } = require("./utils/projects/gasp/details");

async function main() {
  const [deployer] = await ethers.getSigners();

  const DIAMOND_ADDRESS = "0x17f37c992CEe7257820D5B8158D5E914b54d7FAE";
  const createFacetContract = await ethers.getContractAt(
    "XPadCreate",
    DIAMOND_ADDRESS
  );
  await createFacetContract.deployed();

  const createProject = await createFacetContract
    .connect(deployer)
    .createXPad(TXPad);
  await createProject.wait();

  console.log("Success 👍 ", TXPad.xPadProjectId);
}

/*
npx hardhat run scripts/testnet/fuji/create.ts --network avalanche-fuji
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
