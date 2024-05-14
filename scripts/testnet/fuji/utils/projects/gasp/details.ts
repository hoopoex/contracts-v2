import { zeroAddress } from "viem";

const TSocials = {
  web: "https://www.gasp.xyz",
  twitter: "https://twitter.com/gasp_xyz",
  telegram: "/",
  whitepaper: "https://docs.gasp.xyz",
};
const TDetails = {
  slug: "gasp",
  name: "Gasp",
  developer: "-",
  description:
    "Gasp offers native cross-chain swaps without resorting to traditional bridges through the power of escape hatches which guarantee the withdrawal of user funds at all times, ZK proofs and decentralized sequencers.",
  imageLogo: "ipfs://QmYyd2hMAzcPnNjm34rzYQzdo7EBCdcRhvvVkffVj836r3/logo.png",
  imagePoster: "ipfs://QmYyd2hMAzcPnNjm34rzYQzdo7EBCdcRhvvVkffVj836r3/logo.png",
  imageBackground:
    "ipfs://QmYyd2hMAzcPnNjm34rzYQzdo7EBCdcRhvvVkffVj836r3/logo.png",
  socials: TSocials,
  genres: ["DeFi"],
};

const currentTime = Math.floor(Date.now() / 1000);

const TXPad = {
  xPadIsExist: true,
  isView: true,
  itemType: 0,
  xPadDetails: TDetails,
  vestingChaindId: 43113,
  xPadProjectId: 1,
  toBeCollectedValue: 1000000e6,
  collectedValue: 0,
  minDepositValue: 1e6,
  maxDepositValue: 1000e6,
  tokenPrice: 50000, // 0.050000 usdc
  xPadTotalScore: 0,
  xPadRegisterStartDate: currentTime + 1000,
  xPadRegisterEndDate: currentTime + 2000,
  xPadDepositStartDate: currentTime + 3000,
  xPadDepositEndDate: currentTime + 4000,
  vestingContractAddress: zeroAddress,
  projectWalletAddress: "0xE181c949E10e7c5f47B6Ac2Fa461aA5Aa6f11823",
  projectReserveContract: zeroAddress,
};

exports.TXPad = TXPad;
