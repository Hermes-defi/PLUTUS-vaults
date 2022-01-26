// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FancyToken is ERC20 {
    // Decimals are set to 18 by default in `ERC20`
    constructor() public ERC20("FancyToken", "FT") {
        _mint(msg.sender, type(uint256).max);
    }
}
