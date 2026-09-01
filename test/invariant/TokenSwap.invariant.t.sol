// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ITokenSwapPair} from "../../src/interfaces/ITokenSwapPair.sol";
import {TokenSwapFactory} from "../../src/TokenSwapFactory.sol";
import {TokenSwapRouter} from "../../src/TokenSwapRouter.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";
import {TokenSwapHandler} from "./TokenSwapHandler.sol";

/**
 * @title TokenSwapInvariantTest
 * @notice Fase 7: `reserve0 * reserve1 >= k` en swaps; balances ≥ reservas; LP locked.
 */
contract TokenSwapInvariantTest is StdInvariant, Test {
    TokenSwapFactory internal factory;
    TokenSwapRouter internal router;
    MockERC20 internal token0;
    MockERC20 internal token1;
    ITokenSwapPair internal pair;
    TokenSwapHandler internal handler;

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

        handler = new TokenSwapHandler(pair, router, token0, token1);

        // Seed inicial de liquidez.
        address lp = handler.actorsList(0);
        vm.startPrank(lp);
        token0.approve(address(router), 1_000 ether);
        token1.approve(address(router), 1_000 ether);
        router.addLiquidity(
            address(token0), address(token1), 1_000 ether, 1_000 ether, 0, 0, lp, block.timestamp + 1 days
        );
        vm.stopPrank();
        handler.sync();

        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = TokenSwapHandler.mintLiquidity.selector;
        selectors[1] = TokenSwapHandler.swapToken0For1.selector;
        selectors[2] = TokenSwapHandler.swapToken1For0.selector;
        selectors[3] = TokenSwapHandler.burnLiquidity.selector;
        selectors[4] = TokenSwapHandler.warpTime.selector;
        selectors[5] = TokenSwapHandler.sync.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    /// @notice Tras swaps el producto no cae por debajo del ghostK (fee 0.3% ⇒ k no decrece en swap).
    function invariant_kProductAtLeastGhost() public view {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        if (r0 == 0 || r1 == 0) {
            return;
        }
        assertGe(uint256(r0) * r1, handler.ghostK());
    }

    /// @notice Balances on-chain ≥ reservas (excedente solo vía donación / pre-sync).
    function invariant_balancesGeReserves() public view {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertGe(token0.balanceOf(address(pair)), r0);
        assertGe(token1.balanceOf(address(pair)), r1);
    }

    /// @notice MINIMUM_LIQUIDITY permanece bloqueada en `address(0)`.
    function invariant_minimumLiquidityLocked() public view {
        assertEq(IERC20(address(pair)).balanceOf(address(0)), pair.MINIMUM_LIQUIDITY());
    }

    /// @notice ghostK refleja el producto actual de reservas.
    function invariant_ghostKMatchesReserves() public view {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        if (r0 == 0 || r1 == 0) {
            return;
        }
        assertEq(uint256(r0) * r1, handler.ghostK());
    }
}
