# sigma-wallet

## Description
This repo implements the smart contracts for the sigma wallet project developed at ETHGlobalParis hackathon.
The main contracts developed are:
- `ProviderManager.sol`: contract that manages the different providers and its public keys, it allows for the addition of providers (like for example GoogleProvider) as an authentication method.
- `GoogleProvider.sol`: `IProvider.sol` implementation for Google OAuth, allowing the user to log-in with their Google account.
- `SigmaWallet.sol`: Wallet contract, can only be accessed by the entrypoint, validates signatures and executes transactions
- `SigmaWalletFactory.sol`: contract that handles the creation of new wallets in case the user does not have one

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

### Test

To run all tests execute the following commad:

```
make tests
```



# About Us
[Three Sigma](https://threesigma.xyz/) is a venture builder firm focused on blockchain engineering, research, and investment. Our mission is to advance the adoption of blockchain technology and contribute towards the healthy development of the Web3 space.

---

<p align="center">
  <img src="https://threesigma.xyz/_next/image?url=%2F_next%2Fstatic%2Fmedia%2Fthree-sigma-labs-research-capital-white.0f8e8f50.png&w=2048&q=75" width="75%" />
</p>
