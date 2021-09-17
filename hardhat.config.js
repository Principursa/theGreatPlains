require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");
let { privateKey, alchemyUrl, ftmscanApiKey } = require("./secrets.json");

module.exports = {
  defaultNetwork: "hardhat",
  solidity: {
        version: "0.8.7",
    settings: {
      outputSelection: {
        "*": {
          "*": ["storageLayout"]
        }
      }
    }
  },
  networks: {
   hardhat: {
     chainId: 1337,
     allowUnlimitedContractSize: true
   },
    fantom: {

      gas: 12000000,
      url: alchemyUrl,
      accounts: [privateKey]
    }
  },
  etherscan: {
    apiKey: ftmscanApiKey
  }
};
