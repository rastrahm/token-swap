// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {ITokenSwapPair} from "../src/interfaces/ITokenSwapPair.sol";
import {UQ112x112} from "../src/libraries/UQ112x112.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {TokenSwapPair} from "../src/TokenSwapPair.sol";

/**
 * @title TokenSwapPairUpdateTest
 * @notice Fase 2: `sync` / `_update` actualizan reservas y acumuladores TWAP.
 */
contract TokenSwapPairUpdateTest is Test {
    using UQ112x112 for uint224;

    MockERC20 internal token0;
    MockERC20 internal token1;
    TokenSwapPair internal pair;

    address internal donor = makeAddr("donor");

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

        token0.mint(donor, 10_000 ether);
        token1.mint(donor, 10_000 ether);
    }

    /**
     * @notice `sync` alinea reservas con balances y emite `Sync`.
     */
    function test_sync_setsReservesFromBalancesAndEmitsSync() public {
        uint256 amount0 = 100 ether;
        uint256 amount1 = 200 ether;

        vm.startPrank(donor);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true, address(pair));
        emit ITokenSwapPair.Sync(uint112(amount0), uint112(amount1));

        pair.sync();

        (uint112 r0, uint112 r1, uint32 ts) = pair.getReserves();
        assertEq(r0, amount0);
        assertEq(r1, amount1);
        assertEq(ts, uint32(block.timestamp));
        assertEq(pair.price0CumulativeLast(), 0, "no TWAP until prior reserves + elapsed time");
        assertEq(pair.price1CumulativeLast(), 0);
    }

    /**
     * @notice Tras reservas previas y `warp`, `_update` acumula precios TWAP.
     */
    function test_sync_accumulatesTwapAfterTimeElapsed() public {
        uint256 amount0 = 100 ether;
        uint256 amount1 = 100 ether;

        vm.startPrank(donor);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        vm.stopPrank();
        pair.sync();

        uint32 dt = 1000;
        vm.warp(block.timestamp + dt);

        // Sin cambio de balances: solo avanza el acumulador.
        pair.sync();

        uint256 price0 = uint256(UQ112x112.encode(uint112(amount1)).uqdiv(uint112(amount0))) * dt;
        uint256 price1 = uint256(UQ112x112.encode(uint112(amount0)).uqdiv(uint112(amount1))) * dt;

        assertEq(pair.price0CumulativeLast(), price0);
        assertEq(pair.price1CumulativeLast(), price1);

        (,, uint32 ts) = pair.getReserves();
        assertEq(ts, uint32(block.timestamp));
    }

    /**
     * @notice Misma block (dt = 0): no acumula TWAP.
     */
    function test_sync_sameBlock_doesNotAccumulateTwap() public {
        vm.startPrank(donor);
        token0.transfer(address(pair), 50 ether);
        token1.transfer(address(pair), 50 ether);
        vm.stopPrank();
        pair.sync();

        pair.sync();

        assertEq(pair.price0CumulativeLast(), 0);
        assertEq(pair.price1CumulativeLast(), 0);
    }

    /**
     * @notice Balance > uint112.max → `Overflow`.
     */
    function test_sync_revertsOverflow_whenBalanceExceedsUint112() public {
        uint256 tooMuch = uint256(type(uint112).max) + 1;
        token0.mint(donor, tooMuch);

        vm.prank(donor);
        token0.transfer(address(pair), tooMuch);

        // token1 sigue en 0; overflow en token0 basta.
        vm.expectRevert(ITokenSwapPair.Overflow.selector);
        pair.sync();
    }
}
