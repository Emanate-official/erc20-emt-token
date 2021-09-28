// https://docs.openzeppelin.com/upgrades-plugins/1.x/truffle-upgrades
const Token = artifacts.require("Token");
const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

module.exports = async (deployer) => {
  // await deployProxy(Token, ["Emanate", "EMT"], { deployer, kind: "uups" });
  // const existing = await Token.deployed();
  // console.log(existing.address);

  const proxy = "0x73CA2964ed67c914d4ADfadFb8c14B6b0a342B9E";
  const instance = await upgradeProxy(proxy, Token, { deployer, kind: "uups" });
  console.log("Upgraded", instance.address);
};
