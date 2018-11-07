require('dotenv').config();

const Web3 = require("web3");
const web3 = new Web3();
const WalletProvider = require("truffle-wallet-provider");
const Wallet = require('ethereumjs-wallet');

const PARConfig = require('./PARConfig.js');

module.exports = {
	networks: {
		development: {
			host: "localhost",
			port: 8545,
			gas: 4700000,
			gasPrice: web3.toWei("21", "gwei"),
			network_id: "*" // Match any network id
		}

		,ropsten: {
			provider: new WalletProvider( Wallet.fromPrivateKey( new Buffer( PARConfig.networks['ropsten'].operator.key, 'hex' ) ), PARConfig.networks['ropsten'].url ),
			gas: 4700000,
			gasPrice: web3.toWei("21", "gwei"),
			network_id: "3",
		}

		,rinkeby: {
			provider: new WalletProvider( Wallet.fromPrivateKey( new Buffer( PARConfig.networks['rinkeby'].operator.key, 'hex' ) ), PARConfig.networks['rinkeby'].url ),
			gas: 4700000,
			gasPrice: web3.toWei("21", "gwei"),
			network_id: "4",
		}

		,mainnet: {
			provider: new WalletProvider( Wallet.fromPrivateKey( new Buffer( PARConfig.networks['mainnet'].operator.key, 'hex' ) ), PARConfig.networks['mainnet'].url ),
			gas: 4700000,
			gasPrice: web3.toWei("7", "gwei"),
			network_id: "1",
		}
    },
	solc: {
		optimizer: {
			enabled: true,
			runs: 200
		}
	}
};
