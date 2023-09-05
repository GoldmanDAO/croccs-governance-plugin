# Croccs Governance Plugin [![Open in Gitpod][gitpod-badge]][gitpod] [![Github Actions][gha-badge]][gha] [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

[gitpod]: https://gitpod.io/#https://github.com/GoldmanDAO/croccs-governance-plugin
[gitpod-badge]: https://img.shields.io/badge/Gitpod-Open%20in%20Gitpod-FFB45B?logo=gitpod
[gha]: https://github.com/GoldmanDAO/croccs-governance-plugin/actions
[gha-badge]: https://github.com/GoldmanDAO/croccs-governance-plugin/actions/workflows/ci.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

Contracts for a cheap L2 based voting for Aragon DAOs

## What's Inside

-   CrocssPlugin.sol: Contract defining the proposal managment in L1
-   CrocssPluginSetup.sol: Contract helper for CrocssPlugin proxies
-   DAOProxy.sol: Implementacion for L2 proposals logic
-   DAOProxyFactory.sol: Contract factory responsable for deploying DAOProxy clones in L2

## Getting Started

```sh
$ git clone https://github.com/GoldmanDAO/croccs-governance-plugin
$ pnpm install # install Solhint, Prettier, and other Node.js deps
$ forge build
```

If this is your first time with Foundry, check out the
[installation](https://github.com/foundry-rs/foundry#installation) instructions.

## Running Tests

To run the tests simply type:

```sh
$ forge test --vvv
```

## Usage

This is a list of the most frequently needed commands.

### Build

Build the contracts:

```sh
$ forge build
```

### Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

### Compile

Compile the contracts:

```sh
$ forge build
```

### Coverage

Get a test coverage report:

```sh
$ forge coverage
```

### Deploy

Deploy to Anvil:

```sh
$ forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545
```

For this script to work, you need to have a `MNEMONIC` environment variable set to a valid
[BIP39 mnemonic](https://iancoleman.io/bip39/).

For instructions on how to deploy to a testnet or mainnet, check out the
[Solidity Scripting](https://book.getfoundry.sh/tutorials/solidity-scripting.html) tutorial.

### Format

Format the contracts:

```sh
$ forge fmt
```

### Gas Usage

Get a gas report:

```sh
$ forge test --gas-report
```

### Lint

Lint the contracts:

```sh
$ pnpm lint
```

### Test

Run the tests:

```sh
$ forge test
```

## License

This project is licensed under MIT.
