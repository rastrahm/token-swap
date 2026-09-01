// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ITokenSwapPair} from "../../src/interfaces/ITokenSwapPair.sol";
import {ITokenSwapRouter} from "../../src/interfaces/ITokenSwapRouter.sol";
import {TokenSwapFactory} from "../../src/TokenSwapFactory.sol";
import {TokenSwapRouter} from "../../src/TokenSwapRouter.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

/**
 * @title TokenSwapFuzzTest
 * @notice Fase 7: fuzz de amounts y slippage con `bound()` (SWC-101 / K / router).
 */
contract TokenSwapFuzzTest is Test {
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;

    TokenSwapFactory internal factory;
    TokenSwapRouter internal router;
    MockERC20 internal token0;
    MockERC20 internal token1;
    ITokenSwapPair internal pair;

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

        factory = new TokenSwapFactory();
        router = new TokenSwapRouter(address(factory));
        pair = ITokenSwapPair(factory.createPair(address(token0), address(token1)));

        token0.mint(lp, 10_000_000 ether);
        token1.mint(lp, 10_000_000 ether);
        token0.mint(trader, 10_000_000 ether);
        token1.mint(trader, 10_000_000 ether);

        _addLiquidity(lp, 1_000 ether, 1_000 ether);
    }

    /**
     * @notice `getAmountOut` nunca supera la reserva de salida (SWC-101 acotado).
     */
    function testFuzz_getAmountOut_neverExceedsReserve(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
    {
        reserveIn = bound(reserveIn, 1 ether, type(uint112).max);
        reserveOut = bound(reserveOut, 1 ether, type(uint112).max);
        amountIn = bound(amountIn, 1, reserveIn);

        uint256 amountInWithFee = amountIn * 997;
        uint256 amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
        assertLe(amountOut, reserveOut);
    }

    /**
     * @notice Swap vía router: output ≥ amountOutMin y reservas coherentes.
     */
    function testFuzz_router_swap_respectsSlippage(uint256 amountIn) public {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        amountIn = bound(amountIn, 1 ether, uint256(r0) / 10);

        uint256[] memory expected = router.getAmountsOut(amountIn, _path(address(token0), address(token1)));
        uint256 amountOutMin = bound(expected[1], 0, expected[1]);

        uint256 trader1Before = token1.balanceOf(trader);

        vm.startPrank(trader);
        token0.approve(address(router), amountIn);
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            _path(address(token0), address(token1)),
            trader,
            block.timestamp + 1 hours
        );
        vm.stopPrank();

        assertEq(amounts[0], amountIn);
        assertGe(amounts[1], amountOutMin);
        assertEq(token1.balanceOf(trader), trader1Before + amounts[1]);

        (uint112 r0After, uint112 r1After,) = pair.getReserves();
        assertEq(r0After, r0 + uint112(amountIn));
        assertEq(r1After, r1 - uint112(amounts[1]));
    }

    /**
     * @notice Primer mint: liquidez = sqrt(a0*a1) - MINIMUM_LIQUIDITY.
     */
    function testFuzz_firstMint_sqrtGeometry(uint256 amount0, uint256 amount1) public {
        TokenSwapFactory freshFactory = new TokenSwapFactory();
        TokenSwapRouter freshRouter = new TokenSwapRouter(address(freshFactory));
        MockERC20 tA = new MockERC20("A", "A");
        MockERC20 tB = new MockERC20("B", "B");
        if (address(tA) > address(tB)) {
            (tA, tB) = (tB, tA);
        }

        amount0 = bound(amount0, MINIMUM_LIQUIDITY + 1, 1_000_000 ether);
        amount1 = bound(amount1, MINIMUM_LIQUIDITY + 1, 1_000_000 ether);

        ITokenSwapPair freshPair = ITokenSwapPair(freshFactory.createPair(address(tA), address(tB)));
        tA.mint(lp, amount0);
        tB.mint(lp, amount1);

        uint256 expected = _sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;

        vm.startPrank(lp);
        tA.approve(address(freshRouter), amount0);
        tB.approve(address(freshRouter), amount1);
        (,, uint256 liquidity) = freshRouter.addLiquidity(
            address(tA), address(tB), amount0, amount1, 0, 0, lp, block.timestamp + 1 hours
        );
        vm.stopPrank();

        assertEq(liquidity, expected);
        assertEq(IERC20(address(freshPair)).balanceOf(address(0)), MINIMUM_LIQUIDITY);
    }

    /**
     * @notice Swap directo al par aumenta k (fee 0.3%).
     */
    function testFuzz_swap_increasesK(uint256 amountIn) public {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        amountIn = bound(amountIn, 1 ether, uint256(r0) / 20);

        uint256 kBefore = uint256(r0) * r1;
        uint256 amountOut = router.getAmountOut(amountIn, r0, r1);
        if (amountOut == 0 || amountOut >= r1) return;

        vm.startPrank(trader);
        token0.transfer(address(pair), amountIn);
        pair.swap(0, amountOut, trader, "");
        vm.stopPrank();

        (uint112 r0After, uint112 r1After,) = pair.getReserves();
        assertGt(uint256(r0After) * r1After, kBefore);
    }

    /**
     * @notice `amountOutMin` imposible revierte `InsufficientOutputAmount`.
     */
    function testFuzz_router_swap_revertsSlippage(uint256 amountIn, uint256 bump) public {
        (uint112 r0,,) = pair.getReserves();
        amountIn = bound(amountIn, 1 ether, uint256(r0) / 10);
        bump = bound(bump, 1, 1_000 ether);

        uint256[] memory expected = router.getAmountsOut(amountIn, _path(address(token0), address(token1)));

        vm.startPrank(trader);
        token0.approve(address(router), amountIn);
        vm.expectRevert(ITokenSwapRouter.InsufficientOutputAmount.selector);
        router.swapExactTokensForTokens(
            amountIn,
            expected[1] + bump,
            _path(address(token0), address(token1)),
            trader,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
    }

    function _addLiquidity(address provider, uint256 amount0, uint256 amount1) internal {
        vm.startPrank(provider);
        token0.approve(address(router), amount0);
        token1.approve(address(router), amount1);
        router.addLiquidity(
            address(token0),
            address(token1),
            amount0,
            amount1,
            0,
            0,
            provider,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
    }

    function _path(address tokenIn, address tokenOut) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
    }

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
