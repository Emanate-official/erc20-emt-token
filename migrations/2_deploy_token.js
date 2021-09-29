// https://docs.openzeppelin.com/upgrades-plugins/1.x/truffle-upgrades
const Token = artifacts.require("Token");
const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

module.exports = async (deployer, network) => {
  await deployProxy(Token, ["Emanate", "EMT"], { deployer, kind: "uups" });
  
  const token = await Token.deployed();
  console.log(token.address);
  console.log(network);

  let proxy = "0xcF9601B2117B6971c75d3c8C7B3E68a876047D9a"; //"0x73CA2964ed67c914d4ADfadFb8c14B6b0a342B9E";

  if (network === "development") {
    await deployer.deploy(Token, "Emanate", "EMT");
  }

  if (network === "kovan") {
  }

  if (network === "mainnet-fork" || network === "mainnet") {
    // proxy = "0xcF9601B2117B6971c75d3c8C7B3E68a876047D9a";
    // console.log("proxy", proxy);

    // await token.updateBridgeContractAddress("0xce9b04be4e87548d34b8a2180b85310424c84518");
    await token.transferOwnership("0x147a7851e3249D565Efb2eDd112065923cd97FF4"); 
  }

  //const instance = await upgradeProxy(proxy, Token, { deployer, kind: "uups" });
  //console.log("Upgraded", instance.address);
};
