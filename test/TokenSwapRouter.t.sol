// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ITokenSwapPair} from "../src/interfaces/ITokenSwapPair.sol";
import {ITokenSwapRouter} from "../src/interfaces/ITokenSwapRouter.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {TokenSwapFactory} from "../src/TokenSwapFactory.sol";
import {TokenSwapRouter} from "../src/TokenSwapRouter.sol";

/**
 * @title TokenSwapRouterTest
 * @notice Fase 6: add/remove liquidity y swap vía Router con slippage y deadline.
 */
contract TokenSwapRouterTest is Test {
    uint256 internal constant LIQ0 = 1_000 ether;
    uint256 internal constant LIQ1 = 1_000 ether;
    uint256 internal constant SWAP_IN = 10 ether;

    TokenSwapFactory internal factory;
    TokenSwapRouter internal router;
    MockERC20 internal token0;
    MockERC20 internal token1;
    address internal pair;

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
        pair = factory.createPair(address(token0), address(token1));

        token0.mint(lp, 10_000 ether);
        token1.mint(lp, 10_000 ether);
        token0.mint(trader, 10_000 ether);
        token1.mint(trader, 10_000 ether);
    }

    function test_addLiquidity_firstDeposit_mintsLp() public {
        vm.startPrank(lp);
        token0.approve(address(router), LIQ0);
        token1.approve(address(router), LIQ1);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            address(token0),
            address(token1),
            LIQ0,
            LIQ1,
            LIQ0,
            LIQ1,
            lp,
            block.timestamp + 1 hours
        );
        vm.stopPrank();

        assertEq(amountA, LIQ0);
        assertEq(amountB, LIQ1);
        assertGt(liquidity, 0);
        assertGt(IERC20(pair).balanceOf(lp), 0);
    }

    function test_swapExactTokensForTokens_transfersOutput() public {
        _addLiquidityViaRouter(lp, LIQ0, LIQ1);

        uint256[] memory expected = router.getAmountsOut(SWAP_IN, _path(address(token0), address(token1)));
        uint256 trader1Before = token1.balanceOf(trader);

        vm.startPrank(trader);
        token0.approve(address(router), SWAP_IN);
        uint256[] memory amounts = router.swapExactTokensForTokens(
            SWAP_IN,
            expected[1],
            _path(address(token0), address(token1)),
            trader,
            block.timestamp + 1 hours
        );
        vm.stopPrank();

        assertEq(amounts[0], SWAP_IN);
        assertEq(amounts[1], expected[1]);
        assertEq(token1.balanceOf(trader), trader1Before + expected[1]);
    }

    function test_swapExactTokensForTokens_revertsInsufficientOutputAmount() public {
        _addLiquidityViaRouter(lp, LIQ0, LIQ1);

        uint256[] memory expected = router.getAmountsOut(SWAP_IN, _path(address(token0), address(token1)));

        vm.startPrank(trader);
        token0.approve(address(router), SWAP_IN);
        vm.expectRevert(ITokenSwapRouter.InsufficientOutputAmount.selector);
        router.swapExactTokensForTokens(
            SWAP_IN,
            expected[1] + 1,
            _path(address(token0), address(token1)),
            trader,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
    }

    function test_swapExactTokensForTokens_revertsExpired() public {
        _addLiquidityViaRouter(lp, LIQ0, LIQ1);

        vm.startPrank(trader);
        token0.approve(address(router), SWAP_IN);
        vm.expectRevert(ITokenSwapRouter.Expired.selector);
        router.swapExactTokensForTokens(
            SWAP_IN,
            0,
            _path(address(token0), address(token1)),
            trader,
            block.timestamp - 1
        );
        vm.stopPrank();
    }

    function test_swapExactTokensForTokens_revertsInvalidPath() public {
        _addLiquidityViaRouter(lp, LIQ0, LIQ1);

        address[] memory badPath = new address[](1);
        badPath[0] = address(token0);

        vm.startPrank(trader);
        token0.approve(address(router), SWAP_IN);
        vm.expectRevert(ITokenSwapRouter.InvalidPath.selector);
        router.swapExactTokensForTokens(
            SWAP_IN,
            0,
            badPath,
            trader,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
    }

    function test_removeLiquidity_returnsUnderlying() public {
        _addLiquidityViaRouter(lp, LIQ0, LIQ1);

        uint256 lpBalance = IERC20(pair).balanceOf(lp);
        uint256 lp0Before = token0.balanceOf(lp);
        uint256 lp1Before = token1.balanceOf(lp);

        vm.startPrank(lp);
        IERC20(pair).approve(address(router), lpBalance);
        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            address(token0),
            address(token1),
            lpBalance,
            0,
            0,
            lp,
            block.timestamp + 1 hours
        );
        vm.stopPrank();

        assertGt(amountA, 0);
        assertGt(amountB, 0);
        assertGt(token0.balanceOf(lp), lp0Before);
        assertGt(token1.balanceOf(lp), lp1Before);
        assertEq(IERC20(pair).balanceOf(lp), 0);
    }

    function test_addLiquidity_revertsInsufficientBAmount() public {
        _addLiquidityViaRouter(lp, LIQ0, LIQ1);

        vm.startPrank(trader);
        token0.approve(address(router), 100 ether);
        token1.approve(address(router), 100 ether);
        vm.expectRevert(ITokenSwapRouter.InsufficientBAmount.selector);
        router.addLiquidity(
            address(token0),
            address(token1),
            100 ether,
            100 ether,
            0,
            101 ether,
            trader,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
    }

    function _addLiquidityViaRouter(address provider, uint256 amount0, uint256 amount1) internal {
        vm.startPrank(provider);
        token0.approve(address(router), amount0);
        token1.approve(address(router), amount1);
        router.addLiquidity(
            address(token0),
            address(token1),
            amount0,
            amount1,
            amount0,
            amount1,
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
}
