import { ethers } from "hardhat";
import { parseEther, zeroAddress } from "viem";

const { FacetList } = require("../../../libs/facets");
const { getSelectors, FacetCutAction } = require("../../../libs/diamond.js");
const {
  MembershipInitParams,
  NFTParams,
  StakePoolVeriables,
  Times,
  TimeMultiplers,
} = require("./utils/deploysDetails");

async function main() {
  let STAKE_POOL_VERIABLES = StakePoolVeriables;
  let MEMBERSHIP_INIT_PARAMS = MembershipInitParams;
  let NFT_PARAMS = NFTParams;

  const ZERO_ADDR = zeroAddress;
  const R_NAME = "Hoopx Testnet Reserve Contract"; // Hoopx Reserve Contract Name

  const STAKE_LIQUIDITY_AMOUNT_HOOP = parseEther("100000"); // 100000 hoop
  const STAKE_LIQUIDITY_AMOUNT_USDC = 100000000000; // 100000 usdc

  const [deployer] = await ethers.getSigners();

  const diamondFactory = await ethers.getContractFactory("Hoopx");
  const diamondContract = await diamondFactory.deploy();
  await diamondContract.deployed();

  const nftFactory = await ethers.getContractFactory("HOOPNFT");
  const nftContract = await nftFactory.deploy();
  await nftContract.deployed();

  const setMinter = await nftContract
    .connect(deployer)
    .addMinter(diamondContract.address, true);
  await setMinter.wait();

  const reserveFactory = await ethers.getContractFactory("Reserve");
  const reserveContract = await reserveFactory.deploy(R_NAME, deployer.address);
  await reserveContract.deployed();

  const usdcFactory = await ethers.getContractFactory("TestUsdc");
  const usdcContract = await usdcFactory.deploy();
  await usdcContract.deployed();

  const hoopFactory = await ethers.getContractFactory("HoopoeTest");
  const hoopContract = await hoopFactory.deploy();
  await hoopContract.deployed();

  const cut = [];
  for (const FacetName of FacetList) {
    const Facet = await ethers.getContractFactory(FacetName);
    // @ts-ignore
    const facet = await Facet.deploy();
    await facet.deployed();
    console.log(`${FacetName} facet deployed 👍 => ${facet.address}`);
    cut.push({
      target: facet.address,
      action: FacetCutAction.Add,
      selectors: getSelectors(facet),
    });
  }

  const tx = await diamondContract.diamondCut(cut, ZERO_ADDR, "0x");
  await tx.wait();

  const stakeFacet = await ethers.getContractAt(
    "StakeAddition",
    diamondContract.address
  );
  await stakeFacet.deployed();

  const settingFacet = await ethers.getContractAt(
    "Settings",
    diamondContract.address
  );
  await settingFacet.deployed();

  const xpadSetActive = await settingFacet
    .connect(deployer)
    .setXPadActive(true);
  await xpadSetActive.wait();

  const xpadSetUsedTokenAddress = await settingFacet
    .connect(deployer)
    .setXPadUsedTokenAddress(usdcContract.address);
  await xpadSetUsedTokenAddress.wait();

  MEMBERSHIP_INIT_PARAMS.hoopTokenAddress = hoopContract.address;
  MEMBERSHIP_INIT_PARAMS.hoopXReserveAddress = reserveContract.address;
  MEMBERSHIP_INIT_PARAMS.nftContract = nftContract.address;

  const initMembership = await settingFacet
    .connect(deployer)
    .initMembership(MEMBERSHIP_INIT_PARAMS);
  await initMembership.wait();

  const initMembershipNFTs = await settingFacet
    .connect(deployer)
    .initMembershipNFTs(NFT_PARAMS);
  await initMembershipNFTs.wait();

  const setStakeTimes = await settingFacet
    .connect(deployer)
    .addStakeTimes(Times, TimeMultiplers);
  await setStakeTimes.wait();

  STAKE_POOL_VERIABLES.token0ContractAddress = hoopContract.address;
  STAKE_POOL_VERIABLES.token1ContractAddress = usdcContract.address;
  STAKE_POOL_VERIABLES.membershipNFTContractAddress = nftContract.address;

  const setStakePoolVeriables = await settingFacet
    .connect(deployer)
    .setStakePoolVeriables(STAKE_POOL_VERIABLES);
  await setStakePoolVeriables.wait();

  const hoopTokenApproveTx = await hoopContract
    .connect(deployer)
    .approve(stakeFacet.address, STAKE_LIQUIDITY_AMOUNT_HOOP);
  await hoopTokenApproveTx.wait();

  const usdcTokenApproveTx = await usdcContract
    .connect(deployer)
    .approve(stakeFacet.address, STAKE_LIQUIDITY_AMOUNT_USDC);
  await usdcTokenApproveTx.wait();

  const addLiquidityHoop = await stakeFacet
    .connect(deployer)
    .addLiquidity(STAKE_LIQUIDITY_AMOUNT_HOOP, hoopContract.address);
  await addLiquidityHoop.wait();

  const addLiquidityUsdc = await stakeFacet
    .connect(deployer)
    .addLiquidity(STAKE_LIQUIDITY_AMOUNT_USDC, usdcContract.address);
  await addLiquidityUsdc.wait();

  let contractAddresses = new Map<string, string>();
  contractAddresses.set("DIAMOND CONTRACT  => ", diamondContract.address);
  contractAddresses.set("NFT CONTRACT      => ", nftContract.address);
  contractAddresses.set("HOOP CONTRACT     => ", hoopContract.address);
  contractAddresses.set("USDC CONTRACT     => ", usdcContract.address);
  contractAddresses.set("Rese CONTRACT     => ", reserveContract.address);
  console.table(contractAddresses);
}

/*
npx hardhat run scripts/testnet/fuji/deploys.ts --network avalanche-fuji
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
