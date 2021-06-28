// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ICountable.sol";

contract Token is Ownable, ERC20, ICountable {

    uint256 private _holderCount;

    function count() external view override returns (uint256) {
        return _holderCount;
    }

    constructor() ERC20("Emanate", "EMT") {
    }

    function mint(uint256 amount) external onlyBridge() {
        mintWithCount(address(this), amount);
    }

    function mintWithCount(address who, uint256 amount) private {
        if (balanceOf(who) == 0 && amount > 0) {
            _holderCount += 1;
        }

        _mint(who, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (balanceOf(recipient) == 0 && amount > 0) {
            _holderCount += 1;
        }

        if (balanceOf(msg.sender) - amount == 0 && amount > 0) {
            _holderCount += 1;
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
