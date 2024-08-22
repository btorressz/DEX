// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./TheDex.sol";
import "./TheDexFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TheDexRouter {
    address public factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external returns (uint256[] memory amounts) {
        require(path.length >= 2, "Invalid path");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i; i < path.length - 1; i++) {
            address input = path[i];
            address output = path[i + 1];
            address pool = TheDexFactory(factory).getPool(input, output);
            require(pool != address(0), "Pool does not exist");

            TheDex(pool).swapWithSlippageProtection(
                input,
                output,
                amounts[i],
                amounts[i + 1]
            );

            IERC20(output).transfer(to, amounts[i + 1]);
        }

        require(amounts[amounts.length - 1] >= amountOutMin, "Insufficient output amount");
    }
}
