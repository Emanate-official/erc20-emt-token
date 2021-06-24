// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IHolders.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is Ownable, ERC20, IHolders {
    using SafeMath for uint;

    uint256 private _holderCount;

    function holderCount() external view returns (uint256) {
        return _holderCount;
    }

    constructor() ERC20("EMT", "Emante") {

    }

    function mintWithCount(address who, uint256 amount) private {
        if (balanceOf(who) == 0 && amount > 0) {
            _holderCount = _holderCount.add(1);
        }

        _mint(who, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (balanceOf(recipient) == 0 && amount > 0) {
            _holderCount.add(1);
        }

        if (balanceOf(msg.sender).sub(amount) == 0 && amount > 0) {
            _holderCount.sub(1);
        }

        _transfer(_msgSender(), recipient, amount);
        return true;
    }
}
