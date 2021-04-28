const Contract = artifacts.require("Voting");

contract("Voting", async (accounts) => {
  const OWNER = accounts[0];
  const ALICE = accounts[1];
  const BOB = accounts[2];

  let contractInstance;

  describe("Roles and permissions tests", async () => {
    beforeEach(async () => {
      contractInstance = await Contract.new();
    });
  });

  describe("Vote tests", async () => {
    beforeEach(async () => {
      contractInstance = await Contract.new();
    });

    it("should grant alice 100 tokens", async () => {
      await contractInstance.grant(ALICE, 100);

      const actual = await contractInstance.balanceOf(ALICE);
      assert.equal(Number(actual), 100, "Balance should be 100");
    });

    it("should revoke 50 tokens", async () => {
      await contractInstance.grant(ALICE, 100);
      await contractInstance.revoke(ALICE, 50);

      const actual = await contractInstance.balanceOf(ALICE);
      assert.equal(Number(actual), 50, "Balance should be 50");
    });

    it("should create a proposal for alice", async () => {
      await contractInstance.grant(ALICE, 100);
      await contractInstance.addProposal("All the cows are brown");

      const actual = await contractInstance.proposals(0);
      assert.equal(actual.issue, "All the cows are brown", "Proposal issue incorrect");
    });

    it("should be in voting period", async () => {
      await contractInstance.grant(ALICE, 100);
      await contractInstance.addProposal("All the cows are brown");
      await contractInstance.proposals(0);

      const actual = await contractInstance.inVotingPeriod(0)
      assert.equal(actual, true, "Proposal should be in vote period");
    });

    it("should not able to accept own propsal", async () => {
      await contractInstance.grant(ALICE, 100);
      await contractInstance.addProposal("All the cows are brown");
      await contractInstance.proposals(0);

      let actual = await contractInstance.inVotingPeriod(0);
      assert.equal(actual, true, "Proposal should be in vote period");

      try {
        actual = await contractInstance.accept(0, 1);
      } catch (error) {
        assert.equal(error.reason, "Cannot vote on own proposal", `Incorrect revert reason: ${error.reason}`);
      }
    });

    it("should not able to reject own propsal", async () => {
      await contractInstance.grant(ALICE, 100);
      await contractInstance.addProposal("All the cows are brown");
      await contractInstance.proposals(0);

      let actual = await contractInstance.inVotingPeriod(0);
      assert.equal(actual, true, "Proposal should be in vote period");

      try {
        actual = await contractInstance.reject(0, 1);
      } catch (error) {
        assert.equal(error.reason, "Cannot vote on own proposal", `Incorrect revert reason: ${error.reason}`);
      }
    });

    it("should not able to accept without enough tokens", async () => {
      await contractInstance.grant(ALICE, 100);
      await contractInstance.addProposal("All the cows are brown");
      await contractInstance.proposals(0);

      let actual = await contractInstance.inVotingPeriod(0);
      assert.equal(actual, true, "Proposal should be in vote period");

      try {
        actual = await contractInstance.accept(0, 1, { from: BOB });
      } catch (error) {
        assert.equal(error.reason, "Need more tokens", `Incorrect revert reason: ${error.reason}`);
      }
    });

    it("should be able to accept propsal", async () => {
      await contractInstance.grant(ALICE, 100);
      await contractInstance.grant(BOB, 100);
      await contractInstance.addProposal("All the cows are brown");
      await contractInstance.proposals(0);

      await contractInstance.accept(0, 1, { from: BOB });

      const actual = await contractInstance.proposals(0);
      console.log(actual);
      assert.equal(actual.accept, 1, "Accept count should be 1");
      assert.equal(actual.reject, 0, "Reject count should be 0");
    });
  });
});
