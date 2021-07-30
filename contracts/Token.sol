// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./interfaces/ICountable.sol";
import "./interfaces/IMintable.sol";

contract Token is Ownable, ERC20, ERC20Burnable, ICountable, IMintable {

    uint256 private _holderCount;
    address private _bridgeContractAddress;

    constructor() ERC20("Emanate", "EMT") {
        _bridgeContractAddress = msg.sender;
    }

    function mint(address account, uint256 amount) external override onlyBridge() {
        mintWithCount(account, amount);
    }

    function mintWithCount(address account, uint256 amount) private {
        require(account != address(0) && amount > 0, "Invalid arguments");
        if (balanceOf(account) == 0 && amount > 0) {
            _holderCount++;
        }

        _mint(account, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (balanceOf(recipient) == 0 && amount > 0) {
            _holderCount++;
        }

        if (balanceOf(msg.sender) - amount == 0 && amount > 0) {
            _holderCount++;
        }

        _transfer(_msgSender(), recipient, amount);
        return true;
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
