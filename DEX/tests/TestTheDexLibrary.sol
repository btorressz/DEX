// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../contracts/TheDexToken.sol";
import "../contracts/TheDex.sol";
import "../contracts/TheDexFactory.sol";
import "../contracts/Governance.sol";

library TestTheDexLibrary {
    function setup(
        TheDexToken token1,
        TheDexToken token2,
        TheDexFactory factory,
        Governance governance
    ) public returns (TheDex dex) {
        // Deploy TheDexToken
        token1 = new TheDexToken();
        token2 = new TheDexToken();

        // Deploy TheDexFactory
        factory = new TheDexFactory();

        // Create a pool
        factory.createPool(address(token1), address(token2));
        address poolAddress = factory.getPool(address(token1), address(token2));
        dex = TheDex(poolAddress);

        // Deploy Governance
        governance = new Governance(address(token1));

        return dex;
    }
}
