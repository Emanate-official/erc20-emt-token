// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IMintable {
    function mint(address account, uint256 amount) external;
}