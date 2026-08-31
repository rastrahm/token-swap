// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ITokenSwapPair
 * @notice API del par AMM de producto constante (`x * y = k`) con fee 0.3% y TWAP.
 * @dev Selectores de errores/eventos para tests Foundry (`vm.expectRevert` / `vm.expectEmit`).
 *      El par también es ERC-20 (LP shares); esa superficie vive en el contrato, no aquí.
 */
interface ITokenSwapPair {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice `to` es la dirección cero.
    error ZeroAddress();

    /// @notice `amount0Out` y `amount1Out` son ambos cero.
    error InsufficientOutputAmount();

    /// @notice Output solicitado supera las reservas, o liquidez LP calculada es 0.
    error InsufficientLiquidity();

    /// @notice El swap no depositó input (balances no aumentaron).
    error InsufficientInputAmount();

    /// @notice El producto ajustado post-fee viola `k` (`InvalidK`).
    error InvalidK();

    /// @notice Destino del swap es `token0` o `token1` (distorsiona `amountIn`).
    error InvalidTo();

    /// @notice Balance no cabe en `uint112` al actualizar reservas.
    error Overflow();

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /**
     * @notice Liquidez acuñada.
     * @param sender Caller de `mint`.
     * @param amount0 Token0 depositado.
     * @param amount1 Token1 depositado.
     */
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    /**
     * @notice Liquidez quemada.
     * @param sender Caller de `burn`.
     * @param amount0 Token0 retirado.
     * @param amount1 Token1 retirado.
     * @param to Receptor de los tokens subyacentes.
     */
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

    /**
     * @notice Swap ejecutado.
     * @param sender Caller de `swap`.
     * @param amount0In Token0 ingresado.
     * @param amount1In Token1 ingresado.
     * @param amount0Out Token0 enviado a `to`.
     * @param amount1Out Token1 enviado a `to`.
     * @param to Receptor de los outputs.
     */
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /**
     * @notice Reservas sincronizadas con los balances del par.
     * @param reserve0 Nueva reserva token0 (`uint112`).
     * @param reserve1 Nueva reserva token1 (`uint112`).
     */
    event Sync(uint112 reserve0, uint112 reserve1);

    // -------------------------------------------------------------------------
    // Views
    // -------------------------------------------------------------------------

    /**
     * @notice Factory que desplegó este par.
     * @return Dirección de la factory.
     */
    function factory() external view returns (address);

    /**
     * @notice Token del par con dirección menor.
     * @return Dirección de token0.
     */
    function token0() external view returns (address);

    /**
     * @notice Token del par con dirección mayor.
     * @return Dirección de token1.
     */
    function token1() external view returns (address);

    /**
     * @notice Acumulador de precio token0 (TWAP).
     * @return Precio acumulado Q112.
     */
    function price0CumulativeLast() external view returns (uint256);

    /**
     * @notice Acumulador de precio token1 (TWAP).
     * @return Precio acumulado Q112.
     */
    function price1CumulativeLast() external view returns (uint256);

    /**
     * @notice Reservas empaquetadas y timestamp del último `_update`.
     * @return reserve0 Reserva token0.
     * @return reserve1 Reserva token1.
     * @return blockTimestampLast Timestamp (uint32) del último update.
     */
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    /**
     * @notice Liquidez mínima bloqueada en el primer mint (`address(0)`).
     * @return Cantidad constante (1000).
     */
    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    // -------------------------------------------------------------------------
    // Mutating
    // -------------------------------------------------------------------------

    /**
     * @notice Acuña LP shares a `to` según los tokens ya transferidos al par.
     * @param to Receptor de los LP tokens.
     * @return liquidity Cantidad de LP acuñada.
     */
    function mint(address to) external returns (uint256 liquidity);

    /**
     * @notice Quema el balance LP del par y envía token0/token1 a `to`.
     * @param to Receptor de los tokens subyacentes.
     * @return amount0 Token0 enviado.
     * @return amount1 Token1 enviado.
     */
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    /**
     * @notice Intercambia tokens: envía `amount{0,1}Out` a `to` y exige input + K-check.
     * @dev `data` no vacío está reservado; v1 no ejecuta flash-swap callback.
     * @param amount0Out Cantidad de token0 a enviar (0 si no aplica).
     * @param amount1Out Cantidad de token1 a enviar (0 si no aplica).
     * @param to Receptor de los outputs.
     * @param data Payload opcional (debe estar vacío en v1).
     */
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    /**
     * @notice Transfiere el excedente de tokens (balance − reserva) a `to`.
     * @param to Receptor del excedente.
     */
    function skim(address to) external;

    /**
     * @notice Fuerza reservas = balances actuales y actualiza TWAP.
     */
    function sync() external;
}
