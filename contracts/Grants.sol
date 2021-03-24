pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";

struct Proposal {
    uint256 amount;
    address who;
    uint256 expires;
    uint256 accept;
    uint256 reject;
    uint min;
    uint max;
}

contract Grants is Ownable {
    using SafeMath for uint;

    mapping (uint256 => mapping(address => bool)) public votes;
    Proposal[] public proposals;

    address immutable erc20;
    address immutable foundation;

    constant private uint256 duration = 10;

    constructor(address _erc20, address _foundation) public {
        erc20 = _erc20;
        foundation = _foundation;
    }

    function grant(address who, uint256 tokens) public onlyOwner() {
        _balances[who] = _balances[who].add(tokens);
    }

    function revoke(address who, uint256 tokens) public onlyOwner() {
        _balances[who] = _balances[who].sub(tokens);
    }

    function found(uint256 index, uint256 tokens) public {
        _balances[who] = _balances[who].sub(tokens);
        proposals[index].who = proposals[index].amount.add(tokens)
    }

    function inVotingPeriod(uint index) public view returns (bool) {
        return proposals[index].expires > now;
    }

    function apply(uint256 amount) public returns(uint256) {
        // Only token holders can apply
        require(balanceOf(msg.sender) >= 1, "Need at least one token");

        _balances[msg.sender] = _balances[msg.sender].sub(1);
        Grant memory proposal = Proposal(amount, msg.sender, now + 10 days, 0, 0, 1, 1);
        proposals.push(proposal);

        return proposals.length;
    }

    function _vote(uint256 index, bool accept, uint256 amount) private {
        require(proposals[index].who != msg.sender, "Cannot vote on own proposal");
        require(votes[index][msg.sender] != true, "Cannot vote twice");
        require(balanceOf(msg.sender) >= amount, "Need more tokens");
        require(inVotingPeriod(index), "Proposal closed for voting");
        require(amount >= proposals[index].min && proposals[index].max >= amount, "Amount outside the bounds.");

        votes[index][msg.sender] = true;
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        if (accept) {
            proposals[index].accept = proposals[index].accept.add(amount);
        } else {
            proposals[index].reject = proposals[index].accept.add(amount);
        }
        
        emit Vote(index);
        emit Transfer(msg.sender, address(0), amount);
    }

    function accept(uint256 index, uint256 amount) public {
        _vote(index, true, amount);
    }

    function reject(uint256 index, uint256 amount) public {
        _vote(index, false, amount);
    }

    event Vote(uint256 index);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}