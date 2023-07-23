# sigma-wallet

## Descriptionm
This repo implements the smart contracts for the sigma wallet project developed at ETHGlobalParis hackathob.
The main contracts developed are:
- 'ProviderManager.sol': contract that manages the different providers and its public keys, it allows for the addition of providers (like for example GoogleProvider) as an authentication method.
- 'GoogleProvider.sol': 'IProvider.sol' implementation for Google OAuth, allowing the user to log-in with their Google account.
- 'SigmaWallet.sol': Wallet contract, can only be accessed by the entrypoint, validates signatures and executes transactions
- 'SigmaWalletFactory.sol': contract that handles the creation of new wallets in case the user does not have one

These contracts receive interactions from the front/backend and execute them.

## Usage

Here's a list of the most frequently needed commands.

### Build

Build the contracts:

```sh
$ make build
```

### Clean

Delete the build artifacts and cache directories:

```sh
$ make clean
```

### Compile

Compile the contracts:

```sh
$ make build
```

### Deploy

Prior to deployment you must configure the following variables in the `.env` file:

- `MAINNET_RPC_URL/TESTNET_RPC_URL`: An RPC endpoint to connect to the blockchain.
- `PRIVATE_KEY`: The private key for the deployer wallet.
- `ETHERSCAN_API_KEY`: (Optional) An Etherscan API key for contract verification.

Note that a fresh `ETHERSCAN_API_KEY` can take a few minutes to activate, you can query any [endpoint](https://api-rinkeby.etherscan.io/api?module=block&action=getblockreward&blockno=2165403&apikey=ETHERSCAN_API_KEY) to check its status.

#### Local Deployment

By default, Foundry ships with a local Ethereum node [Anvil](https://github.com/foundry-rs/foundry/tree/master/anvil) (akin to Ganache and Hardhat Network). This allows us to quickly deploy to our local network for testing.

To start a local blockchain, with a determined private key, run:

```shthreesigmaxyz/foundry-template
make anvil
```

Afterwards, you can deploy to it via:

```sh
make deploy-anvil contract=<CONTRACT_NAME>
```

#### Testnet Deployment

In order to deploy the contracts to a testnet you must have configured the `TESTNET_RPC_URL` variable. Additionaly, if you need testnet ETH for the deployment you can request it from the following [faucet](https://faucet.paradigm.xyz/).

To execute the deplyment run:

```sh
make deploy-testnet contract=<CONTRACT_NAME>
```

Forge is going to run our script and broadcast the transactions for us. This can take a little while, since Forge will also wait for the transaction receipts.

#### Mainnet Deployment

A mainnet deployment has a similar flow to a testnet deployment with the distinction that it requires you to configure the `MAINNET_RPC_URL` variable.

Afterwards, simply run:

```sh
make deploy-mainnet contract=<CONTRACT_NAME>
```

### Test

To run all tests execute the following commad:

```
make tests
```

Alternatively, you can run specific tests as detailed in this [guide](https://book.getfoundry.sh/forge/tests).


# About Us
[Three Sigma](https://threesigma.xyz/) is a venture builder firm focused on blockchain engineering, research, and investment. Our mission is to advance the adoption of blockchain technology and contribute towards the healthy development of the Web3 space.

---

<p align="center">
  <img src="https://threesigma.xyz/_next/image?url=%2F_next%2Fstatic%2Fmedia%2Fthree-sigma-labs-research-capital-white.0f8e8f50.png&w=2048&q=75" width="75%" />
</p>
