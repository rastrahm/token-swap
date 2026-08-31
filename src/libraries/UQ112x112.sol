// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title UQ112x112
 * @notice Fixed-point UQ112.112 para acumuladores de precio TWAP.
 * @dev Rango `[0, 2**112 - 1]` con resolución `1 / 2**112`. Estilo Uniswap V2.
 */
library UQ112x112 {
    uint224 internal constant Q112 = 2 ** 112;

    /**
     * @notice Codifica un `uint112` como UQ112.112.
     * @param y Valor a codificar.
     * @return z `y * 2**112`.
     */
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112;
    }

    /**
     * @notice Divide un UQ112.112 por un `uint112` (resultado UQ112.112).
     * @param x Numerador en UQ112.112.
     * @param y Denominador.
     * @return z Cociente en UQ112.112.
     */
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}
