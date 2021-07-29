// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './BaseBridge.sol';
import './IBurnable.sol';
import './IMintable.sol';

contract SecondaryBridge is BaseBridge {
	using SafeERC20 for IERC20;

	uint256 private immutable _chainId;
	uint256 public amountIssued;
	
	constructor(address token, uint256 chainId) {
		require(token != address(0), 'Invalid address');
		_token = token;
		_chainId = chainId;
		_authorised = msg.sender;
	}

	function mint(address account, uint256 amount) external onlyAuthorised() returns (bool) {
		require(amount > 0, 'Amount must be greater than 0');
		require(account != address(0), 'Address must be a valid address');
		IMintable(_token).mint(account, amount);
		amountIssued += amount;
		emit Minted(amount, block.timestamp, msg.sender, _chainId);
		return true;
	}

	function burn(uint256 amount) external returns (bool) {
		require(amount > 0, 'Amount must be greater than 0');
		require(amount <= amountIssued, 'Amount must be less than or equal to the amount issued');
		IBurnable(_token).burnFrom(msg.sender, amount);
		amountIssued -= amount;
		emit Burnt(amount, block.timestamp, msg.sender, _chainId);
		return true;
	}

	event Minted(uint256 amount, uint256 timestamp, address indexed to, uint256 chainId);
	event Burnt(uint256 amount, uint256 timestamp, address indexed from, uint256 chainId);
}
