// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./TheDex.sol";

contract TheDexFactory {
    mapping(address => mapping(address => address)) public getPool;
    address[] public allPools;

    event PoolCreated(address indexed token1, address indexed token2, address pool, uint256);

    function createPool(address token1, address token2) external returns (address pool) {
        require(token1 != token2, "Identical addresses");
        require(getPool[token1][token2] == address(0), "Pool already exists");

        bytes memory bytecode = type(TheDex).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token1, token2));
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        TheDex(pool).initialize(token1, token2);
        getPool[token1][token2] = pool;
        allPools.push(pool);

        emit PoolCreated(token1, token2, pool, allPools.length);
    }
}
