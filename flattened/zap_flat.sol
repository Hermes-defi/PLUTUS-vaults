// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/interfaces/IUniRouter01.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: contracts/interfaces/IUniRouter02.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


interface IUniRouter02 is IUniRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts/interfaces/IUniPair.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function balanceOf(address account) external view returns (uint256);
}

// File: contracts/interfaces/IPlutusMinChefVault.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;


interface IPlutusMinChefVault {
    function name() external view returns (string memory);

    function strategy() external view returns (address);

    function allowance(address owner, address spender)
        external
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);

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

// File: contracts/interfaces/IWETH.sol

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

// File: contracts/zap.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;









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
