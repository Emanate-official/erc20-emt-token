// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/ICountable.sol";
import "./interfaces/IMintable.sol";

contract Token is Ownable, ERC20, ICountable, IMintable {

    uint256 private _holderCount;
    address private _bridgeContractAddress;

    function count() external view override returns (uint256) {
        return _holderCount;
    }

    constructor() ERC20("Emanate", "EMT") {
        _bridgeContractAddress = msg.sender;
    }

    function mint(address account, uint256 amount) external override onlyBridge() {
        mintWithCount(account, amount);
    }

    function mintWithCount(address account, uint256 amount) private {
        require(account != address(0) && amount > 0, "Invalid arguments");
        if (balanceOf(account) == 0) {
            _holderCount++;
        }

        _mint(account, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0) && amount > 0, "Invalid arguments");
        
        if (balanceOf(recipient) == 0 && balanceOf(msg.sender) - amount > 0) {
            _holderCount++;
        }

        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) public onlyBridge() {
        require(account != address(0) && amount > 0, "Invalid arguments");
        _burn(account, amount);
        if (balanceOf(account) == 0) {
            _holderCount--;
        }
    }

    function updateBridgeContractAddress(address bridgeContractAddress) public onlyOwner() {
        require(_bridgeContractAddress != address(0), "Bridge address is zero address");
        _bridgeContractAddress = bridgeContractAddress;
    }

    modifier onlyBridge {
        require(msg.sender == _bridgeContractAddress, "Can be called only by bridge contract");   
        _;
    }
}
