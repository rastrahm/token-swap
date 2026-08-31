// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title Math
 * @notice Utilidades matemáticas del AMM (raíz cuadrada entera para liquidez).
 * @dev `sqrt` usa el método babilónico (mismo enfoque que Uniswap V2).
 */
library Math {
    /**
     * @notice Raíz cuadrada entera de `y` (floor).
     * @param y Valor de entrada.
     * @return z `floor(sqrt(y))`.
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @notice Mínimo de dos valores.
     * @param x Primer valor.
     * @param y Segundo valor.
     * @return z El menor de `x` e `y`.
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }
}
