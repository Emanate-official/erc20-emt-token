const Contract = artifacts.require("Grants");

const {
  BN,
  expectEvent,
  expectRevert,
  time,
  constants: { ZERO_ADDRESS },
} = require("@openzeppelin/test-helpers");

const { expect } = require("chai");

contract("Grants", (accounts) => {
  let contract;

  beforeEach(async () => {
    contract = await Contract.new();
  });
});
