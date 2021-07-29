import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { PrimaryBridge } from "../typechain/PrimaryBridge";
import { solidity } from "ethereum-waffle";

chai.use(solidity);

let bridge: any; // Bridge
let mock: any;
let owner: any;
let addr1: any;
let addr2: any;
let addrs: any;

describe("PrimaryBridge", function () {
  before(async () => {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    console.log("===================Deploying Contracts=====================");
    const MockToken = await ethers.getContractFactory("MockToken");
    mock = await MockToken.deploy();
    await mock.deployed();
    console.log(`mock contract deployed at ${mock.address}`);

    const Bridge = await ethers.getContractFactory("PrimaryBridge");
    bridge = await Bridge.deploy(mock.address);
    await bridge.deployed();
    console.log(`Primary bridge contract deployed at ${bridge.address}`);

    expect(await mock.name()).to.equal("MockToken");
    expect(await mock.symbol()).to.equal("MT");
    expect(await bridge.bridgeToken()).to.equal(mock.address);

    const totalSupply = await mock.totalSupply();
    expect(Number(totalSupply)).to.equal(42);

    const ownerBalance = await mock.balanceOf(owner.address);
    expect(Number(ownerBalance)).to.equal(42);

    await mock.mint(addr1.address, 10);

    const addr1Balance = await mock.balanceOf(addr1.address);
    expect(Number(addr1Balance)).to.equal(10);
  });

  it("should have no tokens held on deploy", async () => {
    const amount = await bridge.amountHeld();
    expect(Number(amount)).to.equal(0);
  });

  it("should fire an event and mint tokens when a deposit is placed", async () => {
    const blockNumber = await ethers.provider.getBlockNumber();
    const timestamp = (await ethers.provider.getBlock(blockNumber)).timestamp;

    await mock.approve(bridge.address, 20); // allow bridge to pull tokens
    expect(await bridge.connect(owner).deposit(10))
      .to.emit(bridge, "DepositReceived")
      .withArgs(10, timestamp + 2, owner.address); // 2 seconds from now

    const amountHeld = await bridge.amountHeld();
    expect(Number(amountHeld)).to.equal(10);

    const ownerBalance = await mock.balanceOf(owner.address);
    expect(Number(ownerBalance)).to.equal(32);

    const userBalance = await mock.balanceOf(addr1.address);
    expect(Number(userBalance)).to.equal(10);
  });

  it("should mint tokens", async () => {
    await bridge.mint(addr1.address, 10);

    const totalSupply = await mock.totalSupply();
    expect(Number(totalSupply)).to.equal(62);

    const actual = await mock.balanceOf(addr1.address);
    expect(Number(actual)).to.equal(20);
  });

  // it('should redeem addr1 tokens', async () => {
  // 	let userBalance = await mock.balanceOf(addr1.address)
  // 	expect(Number(userBalance)).to.equal(20)

  // 	await mock.connect(addr1).approve(bridge.address, 10) // allow bridge to pull tokens
  // 	expect(await bridge.connect(addr1).deposit(10))

  // 	let userBalanceAtBridge = await bridge.balanceOf(addr1.address)
  // 	expect(Number(userBalanceAtBridge)).to.equal(10)

  // 	const blockNumber = await ethers.provider.getBlockNumber()
  // 	const timestamp = (await ethers.provider.getBlock(blockNumber)).timestamp

  // 	expect(await bridge.connect(addr1).redeem(5))
  // 	.to.emit(bridge, 'Redeemed')

  // 	const actual = await mock.balanceOf(addr1.address)
  // 	expect(Number(actual)).to.equal(15)

  // 	userBalanceAtBridge = await bridge.balanceOf(addr1.address)
  // 	expect(Number(userBalanceAtBridge)).to.equal(5)
  // })
});
