// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IHolders.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Proposal {
    string issue;
    address who;
    uint256 expires;
    uint256 accept;
    uint min;
}

contract Voting is Ownable {
    using SafeMath for uint;

    mapping (uint256 => mapping(address => bool)) public votes;
    Proposal[] public proposals;
    address private immutable _token;
    address private immutable _foundation;

    constructor(address token, address foundation) public {
        require(token != address(0) && foundation != address(0)));
        _token = token;
        _foundation = foundation;
    }

    function inVotingPeriod(uint index) public view returns (bool) {
        return proposals[index].expires > now;
    }

    function addProposal(string memory issue) public returns(uint256) {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(msg.sender) >= 1, "Need at least one token");

        // transfer to foundation?
        token.transferFrom(msg.sender, _foundation, 1);
        Proposal memory proposal = Proposal(issue, msg.sender, now + 48 hours, 0, 0, 1, 1);
        proposals.push(proposal);

        return proposals.length;
    }

    function accept(uint256 index) public {
        require(proposals[index].who != msg.sender, "Cannot vote on own proposal");
        require(votes[index][msg.sender] != true, "Cannot vote twice");

        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(msg.sender) >= amount, "Need more tokens");
        require(inVotingPeriod(index), "Proposal closed for voting");
        require(amount >= proposals[index].min && proposals[index].max >= amount, "Amount outside the bounds.");

        votes[index][msg.sender] = true;
        //_balances[msg.sender] = _balances[msg.sender].sub(amount);
        token.transferFrom(msg.sender, _foundation, 1);

        proposals[index].accept += 1;

        if (proposals[index].accept > proposals[index].min) {
            // transfer
            emit Transfer(msg.sender, address(0), amount);
        }
        
        emit Vote(index);
    }

    event Vote(uint256 index);
}