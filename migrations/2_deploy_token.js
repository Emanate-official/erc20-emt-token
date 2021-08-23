const Token = artifacts.require("Token");
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

module.exports = async (deployer) => {
  await deployProxy(Token, ["Emanate", "EMT"], { deployer });

  //await deployProxy(Token, ["Emanate", "EMT"]);
};
