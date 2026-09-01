// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ITokenSwapFactory} from "./interfaces/ITokenSwapFactory.sol";
import {TokenSwapPair} from "./TokenSwapPair.sol";

/**
 * @title TokenSwapFactory
 * @notice Despliega y registra pares AMM únicos con tokens ordenados (`token0 < token1`).
 */
contract TokenSwapFactory is ITokenSwapFactory {
    /// @inheritdoc ITokenSwapFactory
    mapping(address => mapping(address => address)) public getPair;

    /// @inheritdoc ITokenSwapFactory
    address[] public allPairs;

    /**
     * @inheritdoc ITokenSwapFactory
     * @dev Ordena tokens, revierte si son idénticos, cero o ya existen.
     */
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        if (tokenA == tokenB) {
            revert IdenticalAddresses();
        }
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) {
            revert ZeroAddress();
        }
        if (getPair[token0][token1] != address(0)) {
            revert PairExists();
        }

        pair = address(new TokenSwapPair(address(this), token0, token1));
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /**
     * @notice Número de pares creados.
     * @return length Cantidad de pares en `allPairs`.
     */
    function allPairsLength() external view returns (uint256 length) {
        return allPairs.length;
    }
}
