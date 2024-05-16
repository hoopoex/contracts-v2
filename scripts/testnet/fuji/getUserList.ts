import { ethers } from "hardhat";
const { TXPad } = require("./utils/projects/gasp/details");

async function main() {
  const [deployer] = await ethers.getSigners();
  const PROJECT_ID = 1;

  const DIAMOND_ADDRESS = "0xD411F6647de6D12ae6476fF531d821d025D63500";
  const queryFacet = await ethers.getContractAt("Query", DIAMOND_ADDRESS);
  await queryFacet.deployed();

  const list = await queryFacet.getXPadUsers(PROJECT_ID);
  console.log(list);
}

/*
npx hardhat run scripts/testnet/fuji/getUserList.ts --network avalanche-fuji
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
