// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BaseBridge.sol";

contract PrimaryBridge is BaseBridge {
    using SafeERC20 for IERC20;

    uint256 public amountHeld;
    address internal immutable self;

    constructor(address token) {
        require(token != address(0), "Invalid address");
        _token = token;
        _authorised = msg.sender;
        self = address(this);
    }

    function deposit(uint256 amount, uint256 chainId) external returns (bool) {
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20(_token).safeTransferFrom(msg.sender, self, amount);
        amountHeld += amount;
        _balances[chainId] += amount;
        emit DepositReceived(amount, chainId, block.timestamp, msg.sender);
        return true;
    }

    function release(uint256 amount, address to, uint256 chainId) external onlyAuthorised() returns (bool) {
        require(amount > 0, "Amount must be greater than 0");
        require(_balances[chainId] >= amount && amount <= amountHeld, "Amount must be greater than or equal to chain balance");

        IERC20(_token).safeTransfer(to, amount);
        amountHeld -= amount;
        _balances[chainId] -= amount;
        emit Released(amount, chainId, block.timestamp, to);
        return true;
    }

    event DepositReceived(uint256 amount, uint256 chainId, uint256 timestamp, address indexed from);
    event Released(uint256 amount, uint256 chainId, uint256 timestamp, address indexed to);
}
