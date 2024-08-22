// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title TheDex
 * @dev An enhanced decentralized exchange (DEX) implementing liquidity pools and token swaps using an AMM algorithm with additional features.
 */
contract TheDex {
    using SafeERC20 for IERC20;

    struct LiquidityPool {
        uint256 token1Reserve;
        uint256 token2Reserve;
        uint256 totalLiquidity;
        mapping(address => uint256) liquidity;
    }

    // Mapping of token pairs to their respective liquidity pools.
    mapping(address => mapping(address => LiquidityPool)) public liquidityPools;

    address public token1Address;
    address public token2Address;
    bool public initialized;

    event LiquidityAdded(address indexed provider, address token1, address token2, uint256 amount1, uint256 amount2);
    event LiquidityRemoved(address indexed provider, address token1, address token2, uint256 amount1, uint256 amount2);
    event SwapExecuted(address indexed trader, address fromToken, address toToken, uint256 amountIn, uint256 amountOut);

    function initialize(address _token1Address, address _token2Address) external {
        require(!initialized, "Already initialized");
        token1Address = _token1Address;
        token2Address = _token2Address;
        initialized = true;
    }

    /**
     * @notice Adds liquidity to a specific token pair pool.
     * @param _token1 The address of the first token.
     * @param _token2 The address of the second token.
     * @param amount1 The amount of the first token to add.
     * @param amount2 The amount of the second token to add.
     */
    function addLiquidity(
        address _token1,
        address _token2,
        uint256 amount1,
        uint256 amount2
    ) external {
        require(_token1 != _token2, "Cannot create pool with identical tokens.");
        require(amount1 > 0 && amount2 > 0, "Amounts must be greater than zero.");
        require(_token1 == token1Address && _token2 == token2Address, "Tokens do not match the pool");

        LiquidityPool storage pool = liquidityPools[_token1][_token2];

        IERC20(_token1).safeTransferFrom(msg.sender, address(this), amount1);
        IERC20(_token2).safeTransferFrom(msg.sender, address(this), amount2);

        pool.token1Reserve += amount1;
        pool.token2Reserve += amount2;

        uint256 liquidityMinted = sqrt(amount1 * amount2);
        pool.totalLiquidity += liquidityMinted;
        pool.liquidity[msg.sender] += liquidityMinted;

        emit LiquidityAdded(msg.sender, _token1, _token2, amount1, amount2);
    }

    /**
     * @notice Removes liquidity from a specific token pair pool.
     * @param _token1 The address of the first token.
     * @param _token2 The address of the second token.
     * @param liquidity The amount of liquidity to remove.
     */
    function removeLiquidity(
        address _token1,
        address _token2,
        uint256 liquidity
    ) external {
        LiquidityPool storage pool = liquidityPools[_token1][_token2];
        require(pool.liquidity[msg.sender] >= liquidity, "Insufficient liquidity.");
        require(_token1 == token1Address && _token2 == token2Address, "Tokens do not match the pool");

        uint256 token1Amount = (liquidity * pool.token1Reserve) / pool.totalLiquidity;
        uint256 token2Amount = (liquidity * pool.token2Reserve) / pool.totalLiquidity;

        pool.liquidity[msg.sender] -= liquidity;
        pool.totalLiquidity -= liquidity;

        pool.token1Reserve -= token1Amount;
        pool.token2Reserve -= token2Amount;

        IERC20(_token1).safeTransfer(msg.sender, token1Amount);
        IERC20(_token2).safeTransfer(msg.sender, token2Amount);

        emit LiquidityRemoved(msg.sender, _token1, _token2, token1Amount, token2Amount);
    }

    /**
     * @notice Swaps an amount of one token for another in a specific token pair pool with slippage protection.
     * @param fromToken The address of the token to swap from.
     * @param toToken The address of the token to swap to.
     * @param amountIn The amount of the fromToken to swap.
     * @param minAmountOut The minimum amount of the toToken expected to receive.
     * @return amountOut The amount of the toToken received.
     */
    function swapWithSlippageProtection(
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut) {
        require(fromToken != toToken, "Cannot swap identical tokens.");
        require(amountIn > 0, "Amount must be greater than zero.");
        require((fromToken == token1Address && toToken == token2Address) || (fromToken == token2Address && toToken == token1Address), "Tokens do not match the pool");

        LiquidityPool storage pool = liquidityPools[fromToken][toToken];

        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 fromTokenReserve = pool.token1Reserve;
        uint256 toTokenReserve = pool.token2Reserve;
        
        uint256 amountInWithFee = amountIn * 997; // Applying a 0.3% fee.
        amountOut = (amountInWithFee * toTokenReserve) / (fromTokenReserve * 1000 + amountInWithFee);

        require(amountOut >= minAmountOut, "Slippage protection: received amount is less than expected.");

        pool.token1Reserve += amountIn;
        pool.token2Reserve -= amountOut;

        IERC20(toToken).safeTransfer(msg.sender, amountOut);

        emit SwapExecuted(msg.sender, fromToken, toToken, amountIn, amountOut);
    }

    /**
     * @notice Calculates the square root of a given number.
     * @param x The number to calculate the square root for.
     * @return y The calculated square root.
     */
    function sqrt(uint256 x) private pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
