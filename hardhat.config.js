require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: {
    version: "0.8.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://rpc.testnet.mantle.xyz",
      },
      allowUnlimitedContractSize: true,
    },

    mantle: {
      url: `https://rpc.testnet.mantle.xyz`,
      accounts: [
        process.env.PRIVATE_KEY
      ],
      allowUnlimitedContractSize: true,
    }
  },
//   gasReporter: {
//     enabled: process.env.REPORT_GAS !== undefined,
//     currency: "USD",
//   },
//   etherscan: {
//     apiKey: "MMTH9PCYDD18ZYA6TKHA51TUKEJ536C33P",
    
//   },
};