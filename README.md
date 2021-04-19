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

## Verify 

`truffle run verify Token --network kovan`