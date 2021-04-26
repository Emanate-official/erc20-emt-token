const Token = artifacts.require("Token");
const Grants = artifacts.require("Grants");

module.exports = function (deployer) {
  deployer.deploy(Token);
};
