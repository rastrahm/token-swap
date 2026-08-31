// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {ITokenSwapPair} from "../src/interfaces/ITokenSwapPair.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {TokenSwapPair} from "../src/TokenSwapPair.sol";

/**
 * @title TokenSwapPairTest
 * @notice Suite TDD del par: mint / swap / burn / K-check.
 * @dev Mint verde (fase 3). Swap/burn en rojo hasta fases 4–5.
 */
contract TokenSwapPairTest is Test {
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;
    uint256 internal constant LIQ0 = 1_000 ether;
    uint256 internal constant LIQ1 = 1_000 ether;
    uint256 internal constant SWAP_IN = 10 ether;

    MockERC20 internal token0;
    MockERC20 internal token1;
    TokenSwapPair internal pair;

    address internal lp = makeAddr("lp");
    address internal trader = makeAddr("trader");

    function setUp() public {
        MockERC20 tokenA = new MockERC20("Token A", "TKA");
        MockERC20 tokenB = new MockERC20("Token B", "TKB");
        if (address(tokenA) < address(tokenB)) {
            token0 = tokenA;
            token1 = tokenB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
        }

        pair = new TokenSwapPair(address(this), address(token0), address(token1));

        token0.mint(lp, 10_000 ether);
        token1.mint(lp, 10_000 ether);
        token0.mint(trader, 10_000 ether);
        token1.mint(trader, 10_000 ether);
    }

    // -------------------------------------------------------------------------
    // Views / constructor
    // -------------------------------------------------------------------------

    function test_constructor_setsImmutablesAndMinimumLiquidity() public view {
        assertEq(pair.factory(), address(this));
        assertEq(pair.token0(), address(token0));
        assertEq(pair.token1(), address(token1));
        assertEq(pair.MINIMUM_LIQUIDITY(), MINIMUM_LIQUIDITY);
        assertTrue(address(token0) < address(token1));
    }

    function test_getReserves_initialAreZero() public view {
        (uint112 r0, uint112 r1, uint32 ts) = pair.getReserves();
        assertEq(r0, 0);
        assertEq(r1, 0);
        assertEq(ts, 0);
    }

    function test_constructor_revertsZeroAddress() public {
        vm.expectRevert(ITokenSwapPair.ZeroAddress.selector);
        new TokenSwapPair(address(0), address(token0), address(token1));
    }

    // -------------------------------------------------------------------------
    // mint
    // -------------------------------------------------------------------------

    /**
     * @notice Primer depósito: `liquidity = sqrt(a0*a1) - MINIMUM_LIQUIDITY` y lock a `address(0)`.
     */
    function test_mint_firstDeposit_locksMinimumLiquidityAndMintsSqrt() public {
        uint256 expectedLiquidity = _sqrt(LIQ0 * LIQ1) - MINIMUM_LIQUIDITY;

        vm.startPrank(lp);
        token0.transfer(address(pair), LIQ0);
        token1.transfer(address(pair), LIQ1);

        vm.expectEmit(true, true, true, true, address(pair));
        emit ITokenSwapPair.Mint(lp, LIQ0, LIQ1);

        uint256 liquidity = pair.mint(lp);
        vm.stopPrank();

        assertEq(liquidity, expectedLiquidity, "LP minted to provider");
        assertEq(pair.balanceOf(lp), expectedLiquidity);
        assertEq(pair.balanceOf(address(0)), MINIMUM_LIQUIDITY, "MINIMUM_LIQUIDITY locked");
        assertEq(pair.totalSupply(), expectedLiquidity + MINIMUM_LIQUIDITY);

        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertEq(r0, LIQ0);
        assertEq(r1, LIQ1);
    }

    /**
     * @notice Depósitos posteriores: pro-rata `min(a0*ts/r0, a1*ts/r1)`.
     */
    function test_mint_subsequent_isProRata() public {
        vm.startPrank(lp);
        token0.transfer(address(pair), LIQ0);
        token1.transfer(address(pair), LIQ1);
        uint256 firstLiq = pair.mint(lp);
        vm.stopPrank();

        // Primer mint debe acuñar LP (fase 3).
        assertGt(firstLiq, 0, "first mint must mint LP before subsequent pro-rata");

        uint256 add0 = 100 ether;
        uint256 add1 = 100 ether;
        uint256 supplyBefore = pair.totalSupply();
        (uint112 r0, uint112 r1,) = pair.getReserves();

        uint256 expected =
            _min((add0 * supplyBefore) / uint256(r0), (add1 * supplyBefore) / uint256(r1));

        uint256 lpBefore = pair.balanceOf(lp);

        vm.startPrank(lp);
        token0.transfer(address(pair), add0);
        token1.transfer(address(pair), add1);
        uint256 liquidity = pair.mint(lp);
        vm.stopPrank();

        assertEq(liquidity, expected);
        assertEq(pair.balanceOf(lp), lpBefore + expected);

        (uint112 r0After, uint112 r1After,) = pair.getReserves();
        assertEq(r0After, uint256(r0) + add0);
        assertEq(r1After, uint256(r1) + add1);
    }

    /**
     * @notice Sin tokens transferidos al par, `mint` revierte `InsufficientLiquidity`.
     */
    function test_mint_revertsInsufficientLiquidity_whenNoTokensTransferred() public {
        vm.prank(lp);
        vm.expectRevert(ITokenSwapPair.InsufficientLiquidity.selector);
        pair.mint(lp);
    }

    // -------------------------------------------------------------------------
    // swap + K
    // -------------------------------------------------------------------------

    /**
     * @notice Swap token0 → token1 con fee 0.3% y K-check válido.
     */
    function test_swap_token0ForToken1_transfersOutAndUpdatesReserves() public {
        _addLiquidity(lp, LIQ0, LIQ1);

        uint256 amountOut = _getAmountOut(SWAP_IN, LIQ0, LIQ1);
        assertGt(amountOut, 0);

        uint256 trader1Before = token1.balanceOf(trader);

        vm.startPrank(trader);
        token0.transfer(address(pair), SWAP_IN);

        vm.expectEmit(true, true, true, true, address(pair));
        emit ITokenSwapPair.Swap(trader, SWAP_IN, 0, 0, amountOut, trader);

        pair.swap(0, amountOut, trader, "");
        vm.stopPrank();

        assertEq(token1.balanceOf(trader), trader1Before + amountOut);

        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertEq(r0, LIQ0 + SWAP_IN);
        assertEq(r1, LIQ1 - amountOut);
    }

    /**
     * @notice Ambos outs en cero → `InsufficientOutputAmount`.
     */
    function test_swap_revertsInsufficientOutputAmount_whenBothOutZero() public {
        _addLiquidity(lp, LIQ0, LIQ1);

        vm.prank(trader);
        vm.expectRevert(ITokenSwapPair.InsufficientOutputAmount.selector);
        pair.swap(0, 0, trader, "");
    }

    /**
     * @notice Out mayor que la reserva → `InsufficientLiquidity`.
     */
    function test_swap_revertsInsufficientLiquidity_whenOutExceedsReserve() public {
        _addLiquidity(lp, LIQ0, LIQ1);

        vm.prank(trader);
        vm.expectRevert(ITokenSwapPair.InsufficientLiquidity.selector);
        pair.swap(0, LIQ1 + 1, trader, "");
    }

    /**
     * @notice Sin input depositado → `InsufficientInputAmount`.
     */
    function test_swap_revertsInsufficientInputAmount_whenNoInput() public {
        _addLiquidity(lp, LIQ0, LIQ1);

        uint256 amountOut = _getAmountOut(SWAP_IN, LIQ0, LIQ1);

        vm.prank(trader);
        vm.expectRevert(ITokenSwapPair.InsufficientInputAmount.selector);
        pair.swap(0, amountOut, trader, "");
    }

    /**
     * @notice Output excesivo respecto al input (fee 0.3%) → `InvalidK`.
     */
    function test_swap_revertsInvalidK_whenOutputBreaksConstantProduct() public {
        _addLiquidity(lp, LIQ0, LIQ1);

        uint256 fairOut = _getAmountOut(SWAP_IN, LIQ0, LIQ1);
        uint256 excessiveOut = fairOut + 1 ether;
        assertTrue(excessiveOut < LIQ1, "still below reserve so K fails first");

        vm.startPrank(trader);
        token0.transfer(address(pair), SWAP_IN);
        vm.expectRevert(ITokenSwapPair.InvalidK.selector);
        pair.swap(0, excessiveOut, trader, "");
        vm.stopPrank();
    }

    /**
     * @notice `to == token0|token1` → `InvalidTo`.
     */
    function test_swap_revertsInvalidTo_whenRecipientIsToken() public {
        _addLiquidity(lp, LIQ0, LIQ1);

        uint256 amountOut = _getAmountOut(SWAP_IN, LIQ0, LIQ1);

        vm.startPrank(trader);
        token0.transfer(address(pair), SWAP_IN);
        vm.expectRevert(ITokenSwapPair.InvalidTo.selector);
        pair.swap(0, amountOut, address(token1), "");
        vm.stopPrank();
    }

    // -------------------------------------------------------------------------
    // burn
    // -------------------------------------------------------------------------

    /**
     * @notice Quema LP del par y recibe pro-rata de token0/token1.
     */
    function test_burn_returnsProRataUnderlying() public {
        vm.startPrank(lp);
        token0.transfer(address(pair), LIQ0);
        token1.transfer(address(pair), LIQ1);
        uint256 minted = pair.mint(lp);
        vm.stopPrank();

        assertGt(minted, 0, "mint must provide LP before burn");

        uint256 lpBalance = pair.balanceOf(lp);
        uint256 supply = pair.totalSupply();
        uint256 balance0 = token0.balanceOf(address(pair));
        uint256 balance1 = token1.balanceOf(address(pair));

        uint256 expected0 = (lpBalance * balance0) / supply;
        uint256 expected1 = (lpBalance * balance1) / supply;

        uint256 lp0Before = token0.balanceOf(lp);
        uint256 lp1Before = token1.balanceOf(lp);

        vm.startPrank(lp);
        pair.transfer(address(pair), lpBalance);

        vm.expectEmit(true, true, true, true, address(pair));
        emit ITokenSwapPair.Burn(lp, expected0, expected1, lp);

        (uint256 amount0, uint256 amount1) = pair.burn(lp);
        vm.stopPrank();

        assertEq(amount0, expected0);
        assertEq(amount1, expected1);
        assertEq(token0.balanceOf(lp), lp0Before + expected0);
        assertEq(token1.balanceOf(lp), lp1Before + expected1);
        assertEq(pair.balanceOf(lp), 0);
        assertEq(pair.balanceOf(address(0)), MINIMUM_LIQUIDITY, "locked liquidity remains");
    }

    /**
     * @notice Sin LP en el par → `InsufficientLiquidity`.
     */
    function test_burn_revertsInsufficientLiquidity_whenNoLpInPair() public {
        _addLiquidity(lp, LIQ0, LIQ1);

        vm.prank(lp);
        vm.expectRevert(ITokenSwapPair.InsufficientLiquidity.selector);
        pair.burn(lp);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    function _addLiquidity(address provider, uint256 amount0, uint256 amount1) internal {
        vm.startPrank(provider);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        pair.mint(provider);
        vm.stopPrank();
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev Raíz cuadrada entera (Babylonian), para expectativas del primer mint.
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
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
}
