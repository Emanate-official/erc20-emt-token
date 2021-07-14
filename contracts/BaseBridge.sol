// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseBridge is Ownable {
    address internal _token;
    address internal _authorised;
    uint256 public amountHeld;

    function bridgeToken() public view returns(address) {
        return address(_token);
    }

    function updateAuthorised(address who) public onlyOwner() {
        require(who != address(0), "Invalid address");
        _authorised = who;        
    }

    modifier onlyAuthorised() {
        require(msg.sender == _authorised, "Caller cannot excute this function");
        _;
    }
}
