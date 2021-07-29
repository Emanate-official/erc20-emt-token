// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockToken is IERC20, ERC20Burnable, Ownable {
  constructor() ERC20("MockToken", "MT") {
    _mint(msg.sender, 42);
  }

  function mint(address account, uint256 amount) external {
    _mint(account, amount);
  }
}
