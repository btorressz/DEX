// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../contracts/TheDexToken.sol";
import "../contracts/TheDex.sol";
import "../contracts/TheDexFactory.sol";
import "../contracts/Governance.sol";
import "./TestTheDexLibrary.sol";

contract TestTheDex {
    using TestTheDexLibrary for *;

    TheDexToken public token1;
    TheDexToken public token2;
    TheDexFactory public factory;
    TheDex public dex;
    Governance public governance;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setup() public {
        dex = TestTheDexLibrary.setup(token1, token2, factory, governance);
    }

    function testAddLiquidity() public returns (bool) {
        setup();

        // Transfer tokens to this contract
        token1.transfer(address(this), 1000);
        token2.transfer(address(this), 1000);

        // Approve and add liquidity
        token1.approve(address(dex), 500);
        token2.approve(address(dex), 500);
        dex.addLiquidity(address(token1), address(token2), 500, 500);

        // Check liquidity
        (uint256 token1Reserve, uint256 token2Reserve, ) = dex.liquidityPools(address(token1), address(token2));
        assert(token1Reserve == 500);
        assert(token2Reserve == 500);

        return true;
    }

    function testRemoveLiquidity() public returns (bool) {
        setup();

        // Transfer tokens to this contract
        token1.transfer(address(this), 1000);
        token2.transfer(address(this), 1000);

        // Approve and add liquidity
        token1.approve(address(dex), 500);
        token2.approve(address(dex), 500);
        dex.addLiquidity(address(token1), address(token2), 500, 500);

        // Remove liquidity
        dex.removeLiquidity(address(token1), address(token2), 500);

        // Check liquidity
        (uint256 token1Reserve, uint256 token2Reserve, ) = dex.liquidityPools(address(token1), address(token2));
        assert(token1Reserve == 0);
        assert(token2Reserve == 0);

        return true;
    }

    function testSwap() public returns (bool) {
        setup();

        // Transfer tokens to this contract
        token1.transfer(address(this), 1000);
        token2.transfer(address(this), 1000);

        // Approve and add liquidity
        token1.approve(address(dex), 500);
        token2.approve(address(dex), 500);
        dex.addLiquidity(address(token1), address(token2), 500, 500);

        // Swap tokens
        token1.approve(address(dex), 100);
        dex.swapWithSlippageProtection(address(token1), address(token2), 100, 1);

        // Check token2 balance
        uint256 token2Balance = token2.balanceOf(address(this));
        assert(token2Balance > 1000); // Ensure token2 balance has increased

        return true;
    }

    function testGovernance() public returns (bool) {
        setup();

        // Transfer tokens to this contract
        token1.transfer(address(this), 1000);

        // Create a proposal
        governance.createProposal("New Proposal");

        // Vote on the proposal
        governance.vote(1);

        // Check proposal vote count
        (, , uint256 voteCount, ) = governance.proposals(1);
        assert(voteCount == 1000);

        return true;
    }
}
