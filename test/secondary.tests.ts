import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { SecondaryBridge } from "../typechain/SecondaryBridge";
import { solidity } from "ethereum-waffle";

chai.use(solidity);

let bridge: any; // Bridge
let mock: any;
let owner: any;
let addr1: any;
let addr2: any;
let addrs: any;

describe("SecondaryBridge", function () {
  before(async () => {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    console.log("===================Deploying Contracts=====================");
    const MockToken = await ethers.getContractFactory("MockToken");
    mock = await MockToken.deploy();
    await mock.deployed();
    console.log(`mock contract deployed at ${mock.address}`);

    const Bridge = await ethers.getContractFactory("SecondaryBridge");
    bridge = await Bridge.deploy(mock.address);
    await bridge.deployed();
    console.log(`bridge contract deployed at ${bridge.address}`);

    expect(await mock.name()).to.equal("MockToken");
    expect(await mock.symbol()).to.equal("MT");
    expect(await bridge.bridgeToken()).to.equal(mock.address);

    const totalSupply = await mock.totalSupply();
    expect(Number(totalSupply)).to.equal(42);

    const ownerBalance = await mock.balanceOf(owner.address);
    expect(Number(ownerBalance)).to.equal(42);

    await mock.mint(addr1.address, 10);
  });

  it("should have no tokens held on deploy", async () => {
    const amount = await bridge.amountHeld();
    expect(Number(amount)).to.equal(0);
  });
});
