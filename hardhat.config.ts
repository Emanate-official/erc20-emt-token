require("dotenv").config();

import "@typechain/hardhat";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-waffle";

export default {
  solidity: "0.8.6",
  networks: {
    hardhat: {
      chainId: 1337,
      accounts: {
        mnemonic: process.env.MNEMONIC,
      },
    },
    kovan: {
      url: process.env.NODE,
      accounts: {
        mnemonic: process.env.MNEMONIC,
      },
    },
    localhost: {
      chainId: 1337,
      url: "http://127.0.0.1:8545/",
    },
  },
};
