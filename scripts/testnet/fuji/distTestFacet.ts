import { ethers } from "hardhat";
import { parseEther } from "viem";

async function main() {
  const [deployer] = await ethers.getSigners();

  const HOOP_ADDRESS = "0xDE07ceb3bcA3625C1b5Db80252081F7Bd531Fb1A";
  const USDC_ADDRESS = "0x5F2fD92FC28fd83a84C385f598a30B3f0Cf91D38";
  const DIST_ADDR = "0x91FfE33bE4f15c0e5865C06626C75e5445e163B3";

  const HOOP_AMOUNT = parseEther("500");
  const USDC_AMOUNT = 1000.0;
  const NATIVE_AMOUNT = parseEther("0.1");

  const DistributeParams = {
    distTokenAmount0: HOOP_AMOUNT,
    distTokenAmount1: USDC_AMOUNT,
    distNativeAmount: NATIVE_AMOUNT,
    distTokenAddr0: HOOP_ADDRESS,
    distTokenAddr1: USDC_ADDRESS,
  };

  const Distribute = await ethers.getContractFactory("DistributeTestT");
  const distribute = await Distribute.deploy(
    DistributeParams,
    deployer.address
  );
  await distribute.deployed();

  console.log("Success 👍 ", distribute.address);
}

/*
npx hardhat run scripts/testnet/fuji/distTestFacet.ts --network avalanche-fuji
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
