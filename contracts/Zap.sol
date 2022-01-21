// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IUniRouter02.sol";
import "./interfaces/IUniPair.sol";
import "./interfaces/IPlutusMinChefVault.sol";
import "./interfaces/IWETH.sol";

//TODO: deploy script  with addr for each vault or use factory?

/**
 * @dev one zap for each vault chef.
 *
 *
 */

contract Zap is Ownable {
    /*
    zapIn              | 0.25% fee. Goes from ETH -> LP tokens and return dust.
    zapInToken         | 0.25% fee. Goes from ERC20 token -> LP and returns dust.
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
    address private FEE_TO_ADDR;
    uint16 FEE_RATE;
    uint16 MIN_AMT;
    mapping(address => mapping(address => address))
        private tokenBridgeForRouter;

    event FeeChange(address fee_to, uint16 rate, uint16 min);

    mapping(address => bool) public useNativeRouter;

    // requires a WONE addr; vault addr;fee collector.
    constructor(
        address _WNATIVE,
        address _vaultChefAddress,
        address feeAddress
    ) public Ownable() {
        WNATIVE = _WNATIVE;
        vaultChefAddress = _vaultChefAddress;
        FEE_TO_ADDR = feeAddress;
        FEE_RATE = 400; // Math is: fee = amount/FEE_RATE, so 400 = 0.25%
        MIN_AMT = 1000;
    }

    /* ========== External Functions ========== */

    receive() external payable {} // contract can receive ETH

    /**
     * @dev Payable function.
     * Swaps from Native coin to an LP token via specified router.
     * Collects a fee for each transaction. see above.
     * Sends fee to fee collector addr
     */
    function zapIn(
        address _to,
        address routerAddr,
        address _recipient,
        address[] memory path0, // WETH -> lptoken1
        address[] memory path1 // WETH -> lptoken2
    ) external payable {
        // from Native to an LP token through the specified router
        require(uint256(msg.value) > MIN_AMT, "INPUT_TOO_LOW");
        uint256 fee = uint256(msg.value).div(FEE_RATE); // set fee

        IWETH(WNATIVE).deposit{value: uint256(msg.value).sub(fee)}(); // mint WETH
        _approveTokenIfNeeded(WNATIVE, routerAddr);
        _swapTokenToLP(
            WNATIVE,
            uint256(msg.value).sub(fee),
            _to,
            _recipient,
            routerAddr,
            path0,
            path1
        );
        safeTransferETH(FEE_TO_ADDR, fee); // collect fee
    }

    /**
     * @dev Swaps from HRC20 token to an LP token via specified router.
     * Collects a fee for each transaction. see above.
     * Sends fee to fee collector addr
     */
    function zapInToken(
        address _from, //from token
        uint256 amount,
        address _to, //to token
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

        // Take fee first because _swapTokenToLP will return dust
        uint256 fee = uint256(amount).div(FEE_RATE);

        IERC20(_from).safeTransfer(
            FEE_TO_ADDR,
            IERC20(_from).balanceOf(address(this))
        ); // transfer All erc 20 token to this contract

        _swapTokenToLP(
            _from,
            amount.sub(fee),
            _to,
            _recipient,
            routerAddr,
            path0,
            path1
        );
    }

    /**
     * @dev does not collect fee.
     *
     */
    function zapInAndStake(
        address _to, // lptoken
        address routerAddr,
        // address _recipient, //msg.sender
        address[] memory path0,
        address[] memory path1 // uint256 vaultPid //pid
    ) external payable {
        // TODO: use delegate call to preserve context
        // Also stakes in vault, no fees
        require(uint256(msg.value) > MIN_AMT, "INPUT_TOO_LOW");
        // not using any vault ID;
        // (address vaultWant, ) = IPlutusMinChefVault(vaultChefAddress).poolInfo(vaultPid);
        // require(vaultWant == _to, "Wrong wantAddress for vault pid");

        IWETH(WNATIVE).deposit{value: uint256(msg.value)}();
        _approveTokenIfNeeded(WNATIVE, routerAddr); // approve if needed
        uint256 lps = _swapTokenToLP(
            WNATIVE, //from token
            uint256(msg.value), //amount
            _to, //to LP
            address(this), //receipient
            routerAddr, //router addr
            path0, //swap path
            path1 //swap path
        );

        // TODO: what happened to dust?

        _approveTokenIfNeeded(_to, vaultChefAddress); //approve token if needed

        // IPlutusMinChefVault(vaultChefAddress).deposit(vaultPid, lps, _recipient); //TODO: remove extra param. only need amount
        IPlutusMinChefVault(vaultChefAddress).deposit(lps); // deposit lp into vault.

        // (bool success,) = address(vaultChefAddress).delegatecall(abi.encodeWithSignature("deposit(uint256)",_amount));
        // require(success, "delegate call fail");

        uint256 zapBalance = IPlutusMinChefVault(vaultChefAddress).balanceOf(
            address(this)
        );
        //send Plutus Sushi USDC-ONE token to msg.sender
        IERC20(vaultChefAddress).safeTransfer(msg.sender, zapBalance);
    }

    function zapInTokenAndStake(
        address _from,
        uint256 amount,
        address _to,
        address routerAddr,
        // address _recipient,
        address[] memory path0,
        address[] memory path1 // uint256 vaultPid
    ) external {
        // Also stakes in vault, no fees
        require(amount > MIN_AMT, "INPUT_TOO_LOW");
        // (address vaultWant, ) = IPlutusMinChefVault(vaultChefAddress).poolInfo(vaultPid);
        // require(vaultWant == _to, "Wrong wantAddress for vault pid");
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
        );
        _approveTokenIfNeeded(_to, vaultChefAddress);
        IPlutusMinChefVault(vaultChefAddress).deposit(lps); //TODO: remove extra
    }

    //swap LPtoken -> NATIVE
    function zapOut(
        address _from, //lptoken
        uint256 amount,
        address routerAddr,
        address _recipient, //msg.sender
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

    function zapOutToken(
        address _from,
        uint256 amount,
        address _to,
        address routerAddr,
        // address _recipient,
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

    // function getWantForVault(uint256 pid) public view returns (address) {
    function getWantForVault() public view returns (address) {
        // (address wantAddress, ) = IPlutusMinChefVault(vaultChefAddress).poolInfo(pid);
        IERC20 wantAddress = IPlutusMinChefVault(vaultChefAddress).want();
        // return wantAddress;
        return address(wantAddress);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }

    function setFee(
        address addr,
        uint16 rate,
        uint16 min
    ) external onlyOwner {
        require(rate >= 25, "FEE TOO HIGH; MAX FEE = 4%");
        FEE_TO_ADDR = addr;
        FEE_RATE = rate;
        MIN_AMT = min;
        emit FeeChange(addr, rate, min);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}
