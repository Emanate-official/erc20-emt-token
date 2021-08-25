// https://docs.openzeppelin.com/upgrades-plugins/1.x/truffle-upgrades
const Token = artifacts.require("Token");
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

module.exports = async (deployer) => {
  await deployProxy(Token, ["Emanate", "EMT"], { deployer });
};
