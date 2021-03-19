# mn8-token
Emanate Token Contract

## Node 12.18.3
The dependencies require Node -v 12.18.3

`nvm use 12.18.3`

## Kovan

`ganache-cli -m carpet dynamic deal utility emerge guide matter child rapid thunder option`

## Flattern the contracts

```bash
cd /path/to/project/src/
npx truffle-flattener contracts/MN8.sol > build/contracts/MN8.flattened.sol

## Registering a contract on Etherscan

The source code will need to be flattened to register a contract on Etherscan.

To flatten the contract code:

```bash
cd /path/to/project/files/
npx truffle-flattener contracts/MN8.sol > build/MN8.flattened.sol
```

Go to Etherscan (https://etherscan.io/) and load the contract. There will be a
"verify" link. Click on this link and specify the following:

Contract Type: single file
Contract Compiler Version: 0.6.0

(There are now two other Contract Types for registering source code; multi-file, and json; these are experimental and will require more investigation).