// https://docs.openzeppelin.com/upgrades-plugins/1.x/truffle-upgrades
const Token = artifacts.require("Token");
const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

module.exports = async (deployer) => {
  await deployProxy(Token, ["Emanate", "EMT"], { deployer, kind: "uups" });
  // const existing = await Token.deployed();
  // const instance = await upgradeProxy(existing.address, Token, { deployer, kind: "uups" });
  // console.log("Upgraded", instance.address);
};
