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

  beforeEach(async () => {
    token = await Token.new();
  });

  describe("deployment", () => {
    it("should get standard ERC20 properties", async () => {
      const symbol = await token.symbol();
      expect(symbol).to.be.equal("EMT");

      const name = await token.name();
      expect(name).to.be.equal("Emante");

      const decimals = await token.decimals();
      expect(decimals).to.be.bignumber.equal(new BN("18"));
      
      const expected = new BN("0");
      const totalSupply = await token.totalSupply();
      expect(totalSupply).to.be.bignumber.equal(expected);
    });

    it("should mint with count", async () => {
      let actual = await token.count();
      let expected = new BN("0");

      expect(actual).to.be.bignumber.equal(expected);

      await token.mint(42);

      actual = await token.count();
      expected = new BN("10000000000000000000000000");
    });

    it.skip("should have holder count as 1", async () => {
      const actual = await token.count();
      const expected = new BN("10000000000000000000000000");

      expect(actual).to.be.bignumber.equal(expected);
    });

    it.skip("should have holder count as 2 after transfer", async () => {
      const actual = await token.count();
      const expected = new BN("10000000000000000000000000");

      expect(actual).to.be.bignumber.equal(expected);
    });
  });
});
