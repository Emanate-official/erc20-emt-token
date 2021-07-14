// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IMintable.sol";
import "./BaseBridge.sol";

contract SecondaryBridge is BaseBridge {
    using SafeERC20 for IERC20;

    constructor(address token) {
        require(token != address(0), "Invalid address");
        _token = token;
        _authorised = msg.sender;
        IERC20(_token).approve(address(this), 1e18); 
    }

    function release(uint256 amount, address to) external returns (bool) {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= amountHeld, "Amount must be less than or equal to amount held");
        amountHeld -= amount;
        IERC20(_token).safeTransferFrom(address(this), to, amount);
        emit Released(amount, msg.sender);
        return true;
    }

    function burn(uint256 amount, address from) external returns (bool) {
        require(amount > 0, "Amount must be greater than 0");
        require(from != address(0), "Invalid address");
        IERC20(_token).safeTransferFrom(from, address(this), amount);
        return true;
    }

    event Released(uint256 amount, address indexed to);
}
