// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./TheDex.sol";
import "./TheDexFactory.sol";
import "./TheDexToken.sol";
import "./Governance.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockContract {
    TheDex public dex;
    TheDexFactory public factory;
    TheDexToken public token1;
    TheDexToken public token2;
    Governance public governance;

    constructor(address _dex, address _factory, address _token1, address _token2, address _governance) {
        dex = TheDex(_dex);
        factory = TheDexFactory(_factory);
        token1 = TheDexToken(_token1);
        token2 = TheDexToken(_token2);
        governance = Governance(_governance);
    }

    function addLiquidity(uint256 amount1, uint256 amount2) external {
        token1.transferFrom(msg.sender, address(this), amount1);
        token2.transferFrom(msg.sender, address(this), amount2);

        token1.approve(address(dex), amount1);
        token2.approve(address(dex), amount2);

        dex.addLiquidity(address(token1), address(token2), amount1, amount2);
    }

    function removeLiquidity(uint256 liquidity) external {
        dex.removeLiquidity(address(token1), address(token2), liquidity);
    }

    function swap(uint256 amountIn, uint256 minAmountOut) external {
        token1.transferFrom(msg.sender, address(this), amountIn);
        token1.approve(address(dex), amountIn);

        dex.swapWithSlippageProtection(address(token1), address(token2), amountIn, minAmountOut);
    }

    function createPool() external {
        factory.createPool(address(token1), address(token2));
    }

    function createProposal(string calldata description) external {
        governance.createProposal(description);
    }

    function vote(uint256 proposalId) external {
        governance.vote(proposalId);
    }
}
