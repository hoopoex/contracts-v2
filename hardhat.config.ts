import type { HardhatUserConfig } from "hardhat/config";
import type { NetworkUserConfig } from "hardhat/types";
import { config as dotenvConfig } from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
import { resolve } from "path";
import "hardhat-diamond-abi";
import "./tasks/accounts";

const { HoopxFacetList } = require("./libs/facets");

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env";
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) });

const mnemonic: string | undefined = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}
const privatekey: string | undefined = process.env.PRIVATE_KEY_TESTNET;
if (!privatekey) {
  throw new Error("Please set your private key in a .env file");
}

const chainIds = {
  mainnet: 1,
  ganache: 1337,
  hardhat: 31337,
  "avalanche-fuji": 43113,
  "arbitrum-mainnet": 42161,
  "chiliz-mainnet": 88888,
};
function getChainConfig(chain: keyof typeof chainIds): NetworkUserConfig {
  let jsonRpcUrl: string;
  switch (chain) {
    case "mainnet":
      jsonRpcUrl = "https://1rpc.io/eth";
      break;
    case "ganache":
      jsonRpcUrl = "http://localhost:8545";
      break;
    case "arbitrum-mainnet":
      jsonRpcUrl = "https://arbitrum.llamarpc.com";
      break;
    case "chiliz-mainnet":
      jsonRpcUrl = "https://rpc.chiliz.com";
      break;
    case "avalanche-fuji":
      jsonRpcUrl = "https://api.avax-test.network/ext/bc/C/rpc";
      break;
    default:
      jsonRpcUrl = "";
      break;
  }
  if (!privatekey) {
    throw new Error("Please set your private key in a .env file");
  }
  return {
    accounts: [privatekey],
    chainId: chainIds[chain],
    url: jsonRpcUrl,
  };
}

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  diamondAbi: {
    strict: false,
    name: "DiamondABI",
    include: HoopxFacetList,
    exclude: [],
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY || "",
      skale: process.env.SKALE_API_KEY || "skalenetwork",
    },
  },
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: "./contracts",
  },
  networks: {
    hardhat: {
      accounts: {
        mnemonic,
      },
      chainId: chainIds.hardhat,
    },
    "arbitrum-mainnet": getChainConfig("arbitrum-mainnet"),
    "chiliz-mainnet": getChainConfig("chiliz-mainnet"),
    ganache: getChainConfig("ganache"),
    mainnet: getChainConfig("mainnet"),
    "avalanche-fuji": getChainConfig("avalanche-fuji"),
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.24",
    settings: {
      evmVersion: "paris",
      metadata: {
        bytecodeHash: "none",
      },
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5",
  },
};

export default config;
