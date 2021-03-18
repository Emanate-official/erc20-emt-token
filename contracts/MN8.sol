// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MN8 is Ownable, ERC20 {

    constructor() ERC20("emanate", "MN8") {
        
    }
}
