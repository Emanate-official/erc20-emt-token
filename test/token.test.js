// https://docs.openzeppelin.com/upgrades-plugins/1.x/truffle-upgrades

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const Token = artifacts.require("Token");

const {
  BN,
  expectEvent,
  expectRevert,
  time,
  constants: { ZERO_ADDRESS },
} = require("@openzeppelin/test-helpers");

const { expect } = require("chai");

contract("Token", (accounts) => {
  let token;
  const owner = accounts[0];
  const bridge_contract = accounts[3];

  beforeEach(async () => {
    token = await deployProxy(Token, ["Emanate", "EMT"]);

    expect(await token.balanceOf(accounts[1])).to.be.bignumber.equal(
      new BN("0")
    );
    expect(await token.balanceOf(accounts[2])).to.be.bignumber.equal(
      new BN("0")
    );

    await token.updateBridgeContractAddress(bridge_contract, { from: owner });
  });

  describe("deployment", () => {
    it("should get standard ERC20 properties", async () => {
      const symbol = await token.symbol();
      expect(symbol).to.be.equal("EMT");

      const name = await token.name();
      expect(name).to.be.equal("Emanate");

      const decimals = await token.decimals();
      expect(decimals).to.be.bignumber.equal(new BN("18"));

      const totalSupply = await token.totalSupply();
      expect(totalSupply).to.be.bignumber.equal(new BN("0"));
    });

    it("should mint with count", async () => {
      let totalSupply = await token.totalSupply();
      let count = await token.count();

      expect(totalSupply).to.be.bignumber.equal(new BN("0"));
      expect(count).to.be.bignumber.equal(new BN("0"));

      await token.mint(accounts[1], 42, { from: bridge_contract });

      count = await token.count();
      const balance = await token.balanceOf(accounts[1]);

      expect(count).to.be.bignumber.equal(new BN("1"));
      expect(await token.totalSupply()).to.be.bignumber.equal(new BN("42"));
      expect(balance).to.be.bignumber.equal(new BN("42"));
    });

    it("should have holder count as 0 after deploy", async () => {
      const actual = await token.count();
      const expected = new BN("0");

      expect(actual).to.be.bignumber.equal(expected);
    });
  });

  describe("transfering and burning", () => {
    it("should have holder count as 2 after transfers", async () => {
      expect(await token.balanceOf(accounts[1])).to.be.bignumber.equal(
        new BN("0")
      );
      expect(await token.balanceOf(accounts[2])).to.be.bignumber.equal(
        new BN("0")
      );

      await token.mint(accounts[1], 100, { from: bridge_contract });
      expect(await token.count()).to.be.bignumber.equal(new BN("1"));

      await token.transfer(accounts[2], 50, { from: accounts[1] });
      expect(await token.count()).to.be.bignumber.equal(new BN("2"));
    });

    it("should burn tokens and not reduce holder count", async () => {
      expect(await token.balanceOf(accounts[1])).to.be.bignumber.equal(
        new BN("0")
      );

      await token.mint(accounts[1], 100, { from: bridge_contract });
      expect(await token.balanceOf(accounts[1])).to.be.bignumber.equal(
        new BN("100")
      );
      expect(await token.count()).to.be.bignumber.equal(new BN("1"));

      await token.transfer(owner, 10, { from: accounts[1] });
      expect(await token.balanceOf(accounts[1])).to.be.bignumber.equal(
        new BN("90")
      );
      expect(await token.balanceOf(owner)).to.be.bignumber.equal(new BN("10"));
      expect(await token.balanceOf(accounts[1])).to.be.bignumber.equal(new BN("90"));

      await token.burn(10, { from: accounts[1] });
      expect(await token.totalSupply()).to.be.bignumber.equal(new BN("90"));
      expect(await token.balanceOf(accounts[1])).to.be.bignumber.equal(new BN("80"));
    });

    it("should burn tokens and reduce holder count", async () => {
      expect(await token.count()).to.be.bignumber.equal(new BN("0"));
      expect(await token.balanceOf(accounts[1])).to.be.bignumber.equal(
        new BN("0")
      );

      await token.mint(accounts[1], 100, { from: bridge_contract });
      expect(await token.balanceOf(accounts[1])).to.be.bignumber.equal(
        new BN("100")
      );
      expect(await token.count()).to.be.bignumber.equal(new BN("1"));

      await token.transfer(owner, 100, { from: accounts[1] });
      expect(await token.count()).to.be.bignumber.equal(new BN("1"));
      expect(await token.balanceOf(accounts[1])).to.be.bignumber.equal(
        new BN("0")
      );
      expect(await token.balanceOf(owner)).to.be.bignumber.equal(new BN("100"));

      await token.burn(100, { from: owner });
      expect(await token.count()).to.be.bignumber.equal(new BN("1"));

      expect(await token.balanceOf(owner)).to.be.bignumber.equal(new BN("0"));
      expect(await token.balanceOf(accounts[1])).to.be.bignumber.equal(
        new BN("0")
      );
    });
  });
});
