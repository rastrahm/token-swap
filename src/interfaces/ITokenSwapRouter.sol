// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ITokenSwapRouter
 * @notice UX de liquidez y swap con protección de slippage y `deadline`.
 * @dev v1: `path` de exactamente 2 tokens (par directo). Sin WETH / multi-hop.
 */
interface ITokenSwapRouter {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice `deadline` ya expiró.
    error Expired();

    /// @notice `amountA` óptimo es menor que `amountAMin`.
    error InsufficientAAmount();

    /// @notice `amountB` óptimo es menor que `amountBMin`.
    error InsufficientBAmount();

    /// @notice Output del swap es menor que `amountOutMin`.
    error InsufficientOutputAmount();

    /// @notice Input requerido supera `amountInMax` (swap inverso, si se usa).
    error ExcessiveInputAmount();

    /// @notice `path.length != 2` o tokens inválidos.
    error InvalidPath();

    /// @notice Receptor o token es `address(0)`.
    error ZeroAddress();

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /**
     * @notice Factory asociada a este router.
     * @return Dirección de la factory.
     */
    function factory() external view returns (address);

    /**
     * @notice Cotiza `amountB` dado `amountA` y reservas (sin fee).
     * @param amountA Cantidad del token A.
     * @param reserveA Reserva de A.
     * @param reserveB Reserva de B.
     * @return amountB Cantidad equivalente de B.
     */
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    /**
     * @notice Output de un swap dado input y reservas (fee 0.3% incluido).
     * @param amountIn Input.
     * @param reserveIn Reserva del token de entrada.
     * @param reserveOut Reserva del token de salida.
     * @return amountOut Output esperado.
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut);

    /**
     * @notice Cadena de amounts para un `path` (v1: 2 tokens).
     * @param amountIn Input inicial.
     * @param path Tokens `[tokenIn, tokenOut]`.
     * @return amounts `[amountIn, amountOut]`.
     */
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    /**
     * @notice Añade liquidez al par; transfiere tokens del caller al par y acuña LP a `to`.
     * @param tokenA Primer token.
     * @param tokenB Segundo token.
     * @param amountADesired Máximo de A a depositar.
     * @param amountBDesired Máximo de B a depositar.
     * @param amountAMin Mínimo de A (slippage).
     * @param amountBMin Mínimo de B (slippage).
     * @param to Receptor de los LP tokens.
     * @param deadline Timestamp Unix máximo.
     * @return amountA A efectivamente depositado.
     * @return amountB B efectivamente depositado.
     * @return liquidity LP acuñado.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /**
     * @notice Retira liquidez: transfiere LP del caller, quema y envía tokenA/tokenB a `to`.
     * @param tokenA Primer token.
     * @param tokenB Segundo token.
     * @param liquidity LP a quemar.
     * @param amountAMin Mínimo de A (slippage).
     * @param amountBMin Mínimo de B (slippage).
     * @param to Receptor de los tokens.
     * @param deadline Timestamp Unix máximo.
     * @return amountA A recibido.
     * @return amountB B recibido.
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @notice Swap exact-in con slippage: `path` de 2 tokens.
     * @param amountIn Input exacto.
     * @param amountOutMin Output mínimo.
     * @param path `[tokenIn, tokenOut]`.
     * @param to Receptor del output.
     * @param deadline Timestamp Unix máximo.
     * @return amounts `[amountIn, amountOut]`.
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}
