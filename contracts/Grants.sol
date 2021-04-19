// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    mapping (address => uint256) public balances;
    Proposal[] public proposals;

    IERC20 immutable erc20; // Token
    address immutable foundation;

    uint256 private constant duration = 10;

    constructor(address _erc20, address _foundation) {
        erc20 = IERC20(_erc20);
        foundation = _foundation;
    }

    function grant(address who, uint256 tokens) public onlyOwner() {
        balances[who] = balances[who].add(tokens);
    }

    function revoke(address who, uint256 tokens) public onlyOwner() {
        balances[who] = balances[who].sub(tokens);
    }

    // function fund(uint256 index, uint256 tokens) public {
    //     balances[who] = balances[who].sub(tokens);
    //     proposals[index].who = proposals[index].amount.add(tokens);
    // }

    function inVotingPeriod(uint index) public view returns (bool) {
        return proposals[index].expires > block.timestamp;
    }

    function applyForGrant(uint256 amount) public returns(uint256) {
        // Only token holders can apply
        require(erc20.balanceOf(msg.sender) >= 1, "Need at least one token");
        Proposal memory proposal = Proposal(amount, msg.sender, block.timestamp + 10 days, 0, 0, 1, 1);
        proposals.push(proposal);

        return proposals.length;
    }

    function _vote(uint256 index, bool accept, uint256 amount) private {
        require(proposals[index].who != msg.sender, "Cannot vote on own proposal");
        require(votes[index][msg.sender] != true, "Cannot vote twice");
        require(erc20.balanceOf(msg.sender) >= amount, "Need more tokens");
        require(inVotingPeriod(index), "Proposal closed for voting");
        require(amount >= proposals[index].min && proposals[index].max >= amount, "Amount outside the bounds.");

        votes[index][msg.sender] = true;
        balances[msg.sender] = balances[msg.sender].sub(amount);

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