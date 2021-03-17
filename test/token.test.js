const Token = artifacts.require("Token");

const {
  BN,
  expectEvent,
  expectRevert,
  time,
  constants: { ZERO_ADDRESS },
} = require("@openzeppelin/test-helpers");

const { expect } = require("chai");

contract("Treasury", (accounts) => {
  const OWNER = accounts[0];
  const OWNER_2 = accounts[1];
  const OWNER_3 = accounts[2];

  const ALICE = accounts[3];
  const BOB = accounts[4];

  const FAST_FORWARD = 60 * 60 * 48;
  const ZERO_BALANCE = new BN(0);

  const Access = { None: "0", Grant: "1", Revoke: "2" };

  const decimals = new BN("18");
  const supply = new BN("1000000").mul(new BN("10").pow(decimals));

  let token;

  beforeEach(async () => {
    token = await Token.new();
  });

  describe("deployment", () => {
    it("should get symbol", async () => {
      const symbol = await token.symbol();
      expect(symbol).to.be.equal("MN8");
    });
  });
});
