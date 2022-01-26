// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IUniRouter02.sol";
import "./interfaces/IUniPair.sol";
import "./interfaces/IPlutusMinChefVault.sol";
import "./interfaces/IWETH.sol";


/**
 * @dev one zap for each vault chef.
 *
 */

contract Zap is Ownable {
    /*
    zapIn              | No fee. Goes from ETH -> LP tokens and return dust.
    zapInToken         | No fee. Goes from ERC20 token -> LP and returns dust.
    zapInAndStake      | No fee.    Goes from ETH -> LP -> Vault and returns dust.
    zapInTokenAndStake | No fee.    Goes from ERC20 token -> LP -> Vault and returns dust.
    zapOut             | No fee.    Breaks LP token and trades it back for ETH.
    zapOutToken        | No fee.    Breaks LP token and trades it back for desired token.
    swap               | No fee.    token for token. Allows us to have a $PLUTUS swap on our site (sitting on top of DFK or Sushi)
    */
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    address public WNATIVE;
    address public vaultChefAddress;
    uint16 MIN_AMT;
    mapping(address => mapping(address => address))
        private tokenBridgeForRouter;

    mapping(address => bool) public useNativeRouter;

    /**
     * @dev requires a WONE addr; vault chef addr;
     */
    constructor(address _WNATIVE, address _vaultChefAddress, address _newOwner) public Ownable() {
        WNATIVE = _WNATIVE;
        vaultChefAddress = _vaultChefAddress;
        MIN_AMT = 1000;
        transferOwnership(_newOwner);

    }

    /* ========== External Functions ========== */

    receive() external payable {} // contract can receive ETH

    /**
     * @dev Payable function.
     * Swaps from Native coin to an LP token via specified router.
     * Does not Stake into vault.
     * @param _to address of lpToken
     * @param routerAddr address of DEX router address
     * @param _recipient address of funds recipient. this could be different from msg.sender.
     * @param path0 list of address that represents the swap order from WETH to lpToken0().
     * @param path1 list of address that represents the swap order from WETH to lpToken1().
     */
    function zapIn(
        address _to,
        address routerAddr,
        address _recipient,
        address[] memory path0,
        address[] memory path1
    ) external payable {
        // from Native to an LP token through the specified router
        require(uint256(msg.value) > MIN_AMT, "INPUT_TOO_LOW");

        IWETH(WNATIVE).deposit{value: uint256(msg.value)}(); // mint WETH
        _approveTokenIfNeeded(WNATIVE, routerAddr);
        _swapTokenToLP(
            WNATIVE,
            uint256(msg.value),
            _to,
            _recipient,
            routerAddr,
            path0,
            path1
        );
    }

    /**
     * @dev Swaps from ERC20 token to an LP token via specified router.
     * Does not Stake into vault.
     * @param _from address of ERC20 token to swap.
     * @param routerAddr address of DEX router address
     * @param _recipient address of funds recipient. NB: This could be different from msg.sender.
     * @param path0 list of address that represents the swap order from ERC20 to lpToken0().
     * @param path1 list of address that represents the swap order from ERC20 to lpToken1().
     */
    function zapInToken(
        address _from,
        uint256 amount,
        address _to,
        address routerAddr,
        address _recipient,
        address[] memory path0,
        address[] memory path1
    ) external {
        // From an ERC20 to an LP token, through specified router
        require(amount > MIN_AMT, "INPUT_TOO_LOW");
        IERC20(_from).safeTransferFrom(msg.sender, address(this), amount); //send token to this contract
        // we'll need this approval to swap
        _approveTokenIfNeeded(_from, routerAddr);

        _swapTokenToLP(
            _from,
            amount,
            _to,
            _recipient,
            routerAddr,
            path0,
            path1
        );
    }

    /**
     * @dev Payable function.
     * Swaps from Native coin to an LP token via specified router.
     * Stake LP token in the vault and receive vault token.
     * Transfer vault token to msg.sender.
     * @param _to address of lpToken
     * @param routerAddr address of DEX router address
     * @param path0 list of address that represents the swap order from ONE to lpToken0().
     * @param path1 list of address that represents the swap order from ONE to lpToken1().
     */
    function zapInAndStake(
        address _to,
        address routerAddr,
        address[] memory path0,
        address[] memory path1
    ) external payable {
        require(uint256(msg.value) > MIN_AMT, "INPUT_TOO_LOW");

        IWETH(WNATIVE).deposit{value: uint256(msg.value)}();
        _approveTokenIfNeeded(WNATIVE, routerAddr); // approve if needed
        uint256 lps = _swapTokenToLP(
            WNATIVE,
            uint256(msg.value),
            _to,
            address(this),
            routerAddr,
            path0,
            path1
        );

        _approveTokenIfNeeded(_to, vaultChefAddress); //approve token if needed

        IPlutusMinChefVault(vaultChefAddress).deposit(lps); // deposit lp into vault.

        //send Plutus Sushi USDC-ONE token to msg.sender
        IERC20(vaultChefAddress).safeTransfer(
            msg.sender,
            IPlutusMinChefVault(vaultChefAddress).balanceOf(address(this))
        );
    }

    /**
     * @dev Swaps from ERC20 token to an LP token via specified router.
     * Stake LP token in the vault and receive vault token.
     * Transfer vault token to msg.sender.
     * requires a minimum deposit amount
     * @param _from address of ERC20
     * @param _to address of lpToken
     * @param routerAddr address of DEX router address
     * @param path0 list of address that represents the swap order from ERC20 to lpToken0().
     * @param path1 list of address that represents the swap order from ERC20 to lpToken1().
     */
    function zapInTokenAndStake(
        address _from,
        uint256 amount,
        address _to,
        address routerAddr,
        address[] memory path0,
        address[] memory path1
    ) external {
        require(amount > MIN_AMT, "INPUT_TOO_LOW");

        IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from, routerAddr);
        uint256 lps = _swapTokenToLP(
            _from,
            amount,
            _to,
            address(this),
            routerAddr,
            path0,
            path1
        ); // keep fund in contract for later staking
        _approveTokenIfNeeded(_to, vaultChefAddress);
        IPlutusMinChefVault(vaultChefAddress).deposit(lps);

        //send Plutus Sushi USDC-ONE token to msg.sender
        IERC20(vaultChefAddress).safeTransfer(
            msg.sender,
            IPlutusMinChefVault(vaultChefAddress).balanceOf(address(this))
        );
    }

    /**
     * @dev Swaps from LP token to NATIVE coin via specified router.
     * @param _from address of lpToken
     * @param routerAddr address of DEX router address
     * @param _recipient address of funds recipient. this could be different from msg.sender.
     * @param path0 list of address that represents the swap order from lpToken0() to Native coin.
     * @param path1 list of address that represents the swap order from lpToken1() to Native coin.
     */
    function zapOut(
        address _from,
        uint256 amount,
        address routerAddr,
        address _recipient,
        address[] memory path0,
        address[] memory path1
    ) external {
        // from an LP token to Native through specified router
        IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from, routerAddr);

        // get pairs for LP
        address token0 = IUniPair(_from).token0();
        address token1 = IUniPair(_from).token1();
        _approveTokenIfNeeded(token0, routerAddr);
        _approveTokenIfNeeded(token1, routerAddr);

        // convert both for Native with msg.sender as recipient
        uint256 amt0;
        uint256 amt1;
        (amt0, amt1) = IUniRouter02(routerAddr).removeLiquidity(
            token0,
            token1,
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );
        _swapTokenForNative(token0, amt0, _recipient, routerAddr, path0);
        _swapTokenForNative(token1, amt1, _recipient, routerAddr, path1);
    }

    /**
     * @dev Swaps from LP token to specified token via specified router.
     * Will automatically swap to Native if WONE if provided as token
     * @param _from address of lpToken
     * @param _to address of ERC20
     * @param routerAddr address of DEX router address
     * @param path0 list of address that represents the swap order from lpToken0() to ERC20 coin.
     * @param path1 list of address that represents the swap order from lpToken1() to ERC20 coin.
     */
    function zapOutToken(
        address _from,
        uint256 amount,
        address _to,
        address routerAddr,
        address[] memory path0,
        address[] memory path1
    ) external {
        // from an LP token to an ERC20 through specified router
        IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from, routerAddr);

        address token0 = IUniPair(_from).token0();
        address token1 = IUniPair(_from).token1();
        _approveTokenIfNeeded(token0, routerAddr);
        _approveTokenIfNeeded(token1, routerAddr);
        uint256 amt0;
        uint256 amt1;
        (amt0, amt1) = IUniRouter02(routerAddr).removeLiquidity(
            token0,
            token1,
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );
        if (token0 != _to) {
            amt0 = _swap(token0, amt0, _to, address(this), routerAddr, path0);
        }
        if (token1 != _to) {
            amt1 = _swap(token1, amt1, _to, address(this), routerAddr, path1);
        }
        _returnAssets(_to);
    }

    /**
     * @dev Simple swap function between two ERC20 tokens using a scpeified router.
     * @param _from address of ERC20
     * @param _to address of ERC20
     * @param routerAddr address of DEX router address
     * @param _recipient address of funds recipient. NB: This could be different from msg.sender.
     * @param path list of address that represents the swap order from ERC20 to ERC20 coin.
     */
    function swapToken(
        address _from,
        uint256 amount,
        address _to,
        address routerAddr,
        address _recipient,
        address[] memory path
    ) external {
        IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from, routerAddr);
        _swap(_from, amount, _to, _recipient, routerAddr, path);
    }

    /* ========== Private Functions ========== */

    /** @dev check if contract has approved @param router to handle its ERC20 token.
     * If not, approve address.
     */
    function _approveTokenIfNeeded(address token, address router) private {
        if (IERC20(token).allowance(address(this), router) == 0) {
            IERC20(token).safeApprove(router, type(uint256).max);
        }
    }

    /**
     * @dev returns the dust funds not added to the lp
     */
    function _returnAssets(address token) private {
        uint256 balance;
        balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            if (token == WNATIVE) {
                IWETH(WNATIVE).withdraw(balance);
                safeTransferETH(msg.sender, balance);
            } else {
                IERC20(token).safeTransfer(msg.sender, balance);
            }
        }
    }

    /**
     * @dev Swap from ERC20 to LP constituant and add liquidity.
     */
    function _swapTokenToLP(
        address _from,
        uint256 amount,
        address _to,
        address recipient,
        address routerAddr,
        address[] memory path0,
        address[] memory path1
    ) private returns (uint256) {
        // get pairs for desired lp
        // we're going to sell 1/2 of _from for each lp token
        uint256 amt0 = amount.div(2);
        uint256 amt1 = amount.div(2);
        if (_from != IUniPair(_to).token0()) {
            // execute swap needed
            amt0 = _swap(
                _from,
                amount.div(2),
                IUniPair(_to).token0(),
                address(this),
                routerAddr,
                path0
            );
        }
        if (_from != IUniPair(_to).token1()) {
            // execute swap
            amt1 = _swap(
                _from,
                amount.div(2),
                IUniPair(_to).token1(),
                address(this),
                routerAddr,
                path1
            );
        }
        _approveTokenIfNeeded(IUniPair(_to).token0(), routerAddr);
        _approveTokenIfNeeded(IUniPair(_to).token1(), routerAddr);
        //add liquidity
        (, , uint256 liquidity) = IUniRouter02(routerAddr).addLiquidity(
            IUniPair(_to).token0(),
            IUniPair(_to).token1(),
            amt0,
            amt1,
            0,
            0,
            recipient,
            block.timestamp
        );
        // Return dust after liquidity is added
        _returnAssets(IUniPair(_to).token0());
        _returnAssets(IUniPair(_to).token1());
        return liquidity;
    }

    /**
     * @dev Implements regular swap functinality with the given router address
     */
    function _swap(
        address _from,
        uint256 amount,
        address _to,
        address recipient,
        address routerAddr,
        address[] memory path
    ) private returns (uint256) {
        if (_from == _to) {
            // Let the swaps handle this logic as well as the path validation
            return amount;
        }
        require(path[0] == _from, "Bad path");
        require(path[path.length - 1] == _to, "Bad path");

        IUniRouter02 router = IUniRouter02(routerAddr);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            recipient,
            block.timestamp
        );
        return IERC20(path[path.length - 1]).balanceOf(address(this));
    }

    /**
     * @dev Implements swap functinality from ERC20 to native.
     */
    function _swapTokenForNative(
        address token,
        uint256 amount,
        address recipient,
        address routerAddr,
        address[] memory path
    ) private returns (uint256) {
        if (token == WNATIVE) {
            // Just withdraw and send
            IWETH(WNATIVE).withdraw(amount);
            safeTransferETH(recipient, amount);
            return amount;
        }
        IUniRouter02 router = IUniRouter02(routerAddr);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            recipient,
            block.timestamp
        );
        return IERC20(path[path.length - 1]).balanceOf(address(this));
    }

    /**
     * @dev returns address of lp token to stake in vault
     */
    function getWantForVault() external view returns (address) {
        IERC20 wantAddress = IPlutusMinChefVault(vaultChefAddress).want();
        // return wantAddress;
        return address(wantAddress);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    /**
     * @dev Allow owner to withdraw any remaining balance of this contract
     * @param token if a zero address, only native will be withdrawn.
     */
    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }

    /**
     * @dev Implements a safe method of transerring ETH between addresses.
     */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}
