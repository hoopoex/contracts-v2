import { ethers } from "hardhat";
const { TXPad } = require("./utils/projects/gasp/details");

async function main() {
  const [deployer] = await ethers.getSigners();

  const DIAMOND_ADDRESS = "0xD221ebDA96e4270C88c76b913345408b85015B4E";
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
