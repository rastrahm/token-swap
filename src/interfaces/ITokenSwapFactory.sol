// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ITokenSwapFactory
 * @notice Crea y registra pares AMM únicos (`token0 < token1`).
 * @dev Selectores de errores/eventos para tests Foundry (`vm.expectRevert` / `vm.expectEmit`).
 */
interface ITokenSwapFactory {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice `tokenA == tokenB`.
    error IdenticalAddresses();

    /// @notice Alguno de los tokens es `address(0)`.
    error ZeroAddress();

    /// @notice Ya existe un par para ese par de tokens.
    error PairExists();

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /**
     * @notice Par creado.
     * @param token0 Token con dirección menor.
     * @param token1 Token con dirección mayor.
     * @param pair Dirección del par desplegado.
     * @param allPairsLength Longitud de `allPairs` tras el alta.
     */
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 allPairsLength);

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /**
     * @notice Dirección del par para (`tokenA`, `tokenB`), o cero si no existe.
     * @param tokenA Primer token (cualquier orden).
     * @param tokenB Segundo token (cualquier orden).
     * @return pair Dirección del par.
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @notice Par en el índice `index` de `allPairs`.
     * @param index Índice 0-based.
     * @return pair Dirección del par.
     */
    function allPairs(uint256 index) external view returns (address pair);

    /**
     * @notice Número de pares creados.
     * @return length Cantidad de pares.
     */
    function allPairsLength() external view returns (uint256 length);

    /**
     * @notice Despliega un par nuevo. Ordena internamente `token0 < token1`.
     * @param tokenA Primer token.
     * @param tokenB Segundo token.
     * @return pair Dirección del par creado.
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
