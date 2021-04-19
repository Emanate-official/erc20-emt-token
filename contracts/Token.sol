// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is Ownable, ERC20 {

    address immutable private _existing_holders;
    address immutable private _outlier_ventures;
    address immutable private _investors;
    address immutable private _foundation;
    address immutable private _growth;
    address immutable private _advisors;
    address immutable private _curve;

    uint256 private _holderCount;

    function holderCount() public view returns (uint256) {
        return _holderCount;
    }

    constructor() ERC20("moda", "MODA") {
        _existing_holders = 0x0364eAA7C884cb5495013804275120ab023619A5;
        _outlier_ventures = 0x0364eAA7C884cb5495013804275120ab023619A5;
        _investors = 0x0364eAA7C884cb5495013804275120ab023619A5;
        _foundation = 0x0364eAA7C884cb5495013804275120ab023619A5;
        _growth = 0x0364eAA7C884cb5495013804275120ab023619A5;
        _advisors = 0x0364eAA7C884cb5495013804275120ab023619A5;
        _curve = 0x0364eAA7C884cb5495013804275120ab023619A5;

        _mint(0x0364eAA7C884cb5495013804275120ab023619A5, 2000000 * 10 ** 18);
        _mint(0x0364eAA7C884cb5495013804275120ab023619A5, 300000 * 10 ** 18);
        _mint(0x0364eAA7C884cb5495013804275120ab023619A5, 500000 * 10 ** 18);
        _mint(0x0364eAA7C884cb5495013804275120ab023619A5, 3500000 * 10 ** 18);
        _mint(0x0364eAA7C884cb5495013804275120ab023619A5, 1000000 * 10 ** 18);
        _mint(0x0364eAA7C884cb5495013804275120ab023619A5, 1200000 * 10 ** 18);
        _mint(0x0364eAA7C884cb5495013804275120ab023619A5, 1500000 * 10 ** 18);
    }

    // function mintWithCount(address who, uint256 amount) private {

    // }
}
