// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./interfaces/ICountable.sol";
import "./interfaces/IBurnable.sol";

contract Token is Ownable, ERC20, ICountable, IBurnable {

    uint256 private _holderCount;
    address private _bridgeContractAddress;

    function count() external view override returns (uint256) {
        return _holderCount;
    }

    constructor() ERC20("Emanate", "EMT") {
    }

    function mint(uint256 amount) external onlyBridge() {
        mintWithCount(address(this), amount);
    }

    function burnFrom(address account, uint256 amount) external onlyBridge() {
        _burn(account, amount);
    }

    function mintWithCount(address who, uint256 amount) private {
        if (balanceOf(who) == 0 && amount > 0) {
            _holderCount++;
        }

        _mint(who, amount);
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
        require(msg.sender == _bridgeContractAddress, "Can be called only by bridge Contract");   
        _;
    }
}
