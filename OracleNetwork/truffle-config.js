const HDWalletProvider = require('@truffle/hdwallet-provider');  // @notice - Should use new module.
const mnemonic = process.env.MNEMONIC;

/// Arbitrum testnet
const wrapProvider = require('arb-ethers-web3-bridge').wrapProvider
const arbProviderUrl = "https://kovan4.arbitrum.io/rpc"


module.exports = {
  networks: {
    arbitrum: {  /// [Note]: The definition of "arbitrum" should be outside of "networks"
      provider: function () {
        // return wrapped provider:
        return wrapProvider(
          new HDWalletProvider(mnemonic, arbProviderUrl)
        )
      },
      network_id: '*',
      gasPrice: 0,
      from: process.env.DEPLOYER_ADDRESS  /// [Note]: Need to specify "from" address
    },      
    kovan: {
      provider: () => new HDWalletProvider(mnemonic, 'https://kovan.infura.io/v3/' + process.env.INFURA_KEY),
      network_id: '42',
      gas: 6465030,
      gasPrice: 5000000000, // 5 gwei
      //gasPrice: 100000000000,  // 100 gwei
      skipDryRun: true,     // Skip dry run before migrations? (default: false for public nets)
    },
    local: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*',
      skipDryRun: true,
      gasPrice: 5000000000
    },
    test: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*',
      skipDryRun: true,
      gasPrice: 5000000000
    }
  },

  compilers: {
    solc: {
      version: "pragma",  /// For compiling multiple solc-versions
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
}
