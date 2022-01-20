// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPlutusMinChefVault {
    function name() external view returns (string memory);

    function strategy() external view returns (address);

    function allowance(address owner, address spender)
        external
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // function safeTransfer(address account, uint256 amount) external;

    function want() external view returns (IERC20);

    function balance() external view returns (uint256);

    function available() external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function depositAll() external;

    function deposit(uint256 _amount) external;

    function earn() external;

    function withdrawAll() external;

    function withdraw(uint256 _shares) external;

    function proposeStrat(address _implementation) external;

    function upgradeStrat() external;

    function inCaseTokensGetStuck(address _token) external;
}
