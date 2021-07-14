// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IMintable.sol";
import "./BaseBridge.sol";

contract PrimaryBridge is BaseBridge {
    using SafeERC20 for IERC20;

    constructor(address token) {
        require(token != address(0), "Invalid address");
        _token = token;
        _authorised = msg.sender;
        IERC20(_token).approve(address(this), 1e18); 
    }

    function deposit(uint256 amount) external returns (bool) {
        require(amount > 0, "Amount must be greater than 0");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), amount);
        amountHeld += amount;
        emit DepositReceived(amount, block.timestamp, msg.sender);
        return true;
    }

    function mint(address account, uint256 amount) external onlyAuthorised() returns (bool) {
        require(amount > 0, "Amount must be greater than 0");
        require(account != address(0), "Invalid address");
        IMintable(_token).mint(account, amount);
        emit Minted(amount, block.timestamp, msg.sender);
        return true;
    }

    event DepositReceived(uint256 amount, uint256 timestamp, address indexed from);
    event Minted(uint256 amount, uint256 timestamp, address indexed to);
}
