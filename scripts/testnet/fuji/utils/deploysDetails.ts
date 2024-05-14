import { parseEther, zeroAddress } from "viem";

const Tortullix = parseEther("1");
const Woolvenia = parseEther("2");
const Bouncebyte = parseEther("3");
const Stagora = parseEther("4");
const Honeyheart = parseEther("5");
const PiggyPrime = parseEther("6");
const HoopX = parseEther("7");
const PrimeBull = parseEther("8");
const Wolvenix = parseEther("9");
const Whalesong = parseEther("10");

const NFTParams = [
  {
    nftIsExist: true,
    tokenID: Tortullix,
    price: parseEther("1"),
  },
  {
    nftIsExist: true,
    tokenID: Woolvenia,
    price: parseEther("2"),
  },
  {
    nftIsExist: true,
    tokenID: Bouncebyte,
    price: parseEther("3"),
  },
  {
    nftIsExist: true,
    tokenID: Stagora,
    price: parseEther("4"),
  },
  {
    nftIsExist: true,
    tokenID: Honeyheart,
    price: parseEther("5"),
  },
  {
    nftIsExist: true,
    tokenID: PiggyPrime,
    price: parseEther("6"),
  },
  {
    nftIsExist: true,
    tokenID: HoopX,
    price: parseEther("8"),
  },
  {
    nftIsExist: true,
    tokenID: PrimeBull,
    price: parseEther("15"),
  },
  {
    nftIsExist: true,
    tokenID: Wolvenix,
    price: parseEther("25"),
  },
  {
    nftIsExist: true,
    tokenID: Whalesong,
    price: parseEther("40"),
  },
];
const AllNFTs = [
  Tortullix,
  Woolvenia,
  Bouncebyte,
  Stagora,
  Honeyheart,
  PiggyPrime,
  HoopX,
  PrimeBull,
  Wolvenix,
  Whalesong,
];

const MembershipInitParams = {
  membershipIsActive: true,
  acceptableTokenIdForHoopX: 0,
  balancedOneHoop: 70,
  buyPrice: parseEther("0.0012"),
  buyNFTBurnPercentage: 70,
  buyNFTReservePercentage: 30,
  upgradePrice: parseEther("0.0012"),
  upgradeNFTBurnPercentage: 70,
  upgradeNFTReservePercentage: 30,
  tokenIDs: AllNFTs,
  hoopXTokenAddress: zeroAddress,
  hoopTokenAddress: zeroAddress,
  hoopXReserveAddress: zeroAddress,
  nftContract: zeroAddress,
};

// 2678400,
const Times: number[] = [
  300, 7862400, 15638400, 31190400, 62294400, 93398400, 124502400, 155606400,
];
const TimeMultiplers = [
  parseEther("1"),
  parseEther("1.5"),
  parseEther("2"),
  parseEther("4"),
  parseEther("8"),
  parseEther("12"),
  parseEther("16"),
  parseEther("20"),
];
const StakePoolVeriables = {
  isActive: true,
  minimumStakeAmount: parseEther("1"),
  minimumUpdateStakeAmount: parseEther("1"),
  minimumLockTime: Times[0],
  maximumLockTime: Times[Times.length - 1],
  token0ContractAddress: zeroAddress,
  token1ContractAddress: zeroAddress,
  membershipNFTContractAddress: zeroAddress,
};

exports.MembershipInitParams = MembershipInitParams;
exports.StakePoolVeriables = StakePoolVeriables;
exports.TimeMultiplers = TimeMultiplers;
exports.NFTParams = NFTParams;
exports.Times = Times;
