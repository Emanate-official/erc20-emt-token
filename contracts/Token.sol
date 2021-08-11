// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ICountable.sol";
import "./interfaces/IMintable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract Token is ERC20Upgradeable, ICountable, IMintable {

    uint256 private _holderCount;
    address private _bridgeContractAddress;

    uint256 private _max_supply = 208_000_000 * 10**18;
    address private _owner;

    function count() external view override returns (uint256) {
        return _holderCount;
    }

    function initialize(string memory name, string memory symbol) initializer public {
        _owner == msg.sender;
        __ERC20_init(name, symbol);
     }

    function mint(address account, uint256 amount) external override onlyBridge() {
        require(_max_supply > totalSupply() + amount, "Cap has been reached");
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

    function burn(uint256 amount) public onlyBridge() {
        require(amount > 0, "Invalid arguments");
        _burn(msg.sender, amount);
    }

    function updateBridgeContractAddress(address bridgeContractAddress) public onlyOwner() {
        require(_bridgeContractAddress != address(0), "Bridge address is zero address");
        _bridgeContractAddress = bridgeContractAddress;
    }

    modifier onlyBridge {
        require(msg.sender == _bridgeContractAddress, "Can be called only by bridge contract");   
        _;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Can be called only by owner");
        _;
    }
}
