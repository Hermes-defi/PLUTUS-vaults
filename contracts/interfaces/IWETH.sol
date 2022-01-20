// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IWETH {
    function name() external view returns (string memory);

    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}
