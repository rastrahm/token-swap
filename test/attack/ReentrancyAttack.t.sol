// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {ReentrancyGuard} from "../../src/utils/ReentrancyGuard.sol";
import {TokenSwapPair} from "../../src/TokenSwapPair.sol";
import {MockERC20Reentrant} from "../mocks/MockERC20Reentrant.sol";

/**
 * @title ReentrancyAttackTest
 * @notice Fase 7 / SWC-107: callbacks ERC-20 maliciosos no reentran en mint/swap/burn.
 * @dev Referencia: `doc/SWC-AUDIT.md` · patrón monorepo `04-erc721`.
 */
contract ReentrancyAttackTest is Test {
    MockERC20Reentrant internal token0;
    MockERC20Reentrant internal token1;
    TokenSwapPair internal pair;

    address internal lp = makeAddr("lp");
    address internal trader = makeAddr("trader");

    function setUp() public {
        MockERC20Reentrant tokenA = new MockERC20Reentrant("Token A", "TKA");
        MockERC20Reentrant tokenB = new MockERC20Reentrant("Token B", "TKB");
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

    /**
     * @notice SWC-107: reentrada cruzada `mint` durante `swap` (transfer de salida).
     */
    function test_Attack_reenterMint_duringSwap_revertsGuard() public {
        _seedLiquidity();

        uint256 amountOut = 1 ether;
        token1.configure(pair, MockERC20Reentrant.Attack.ReenterMint, trader, 0);

        vm.startPrank(trader);
        token0.transfer(address(pair), 10 ether);
        vm.expectRevert(ReentrancyGuard.ReentrancyGuardReentrantCall.selector);
        pair.swap(0, amountOut, trader, "");
        vm.stopPrank();
    }

    /**
     * @notice SWC-107: reentrada en `swap` durante transfer de salida.
     */
    function test_Attack_reenterSwap_revertsGuard() public {
        _seedLiquidity();

        uint256 amountOut = 1 ether;
        token1.configure(pair, MockERC20Reentrant.Attack.ReenterSwap, trader, amountOut);

        vm.startPrank(trader);
        token0.transfer(address(pair), 10 ether);
        vm.expectRevert(ReentrancyGuard.ReentrancyGuardReentrantCall.selector);
        pair.swap(0, amountOut, trader, "");
        vm.stopPrank();
    }

    /**
     * @notice SWC-107: reentrada en `burn` durante transfer de salida.
     */
    function test_Attack_reenterBurn_revertsGuard() public {
        _seedLiquidity();

        uint256 lpBal = pair.balanceOf(lp);
        token0.configure(pair, MockERC20Reentrant.Attack.ReenterBurn, lp, 0);

        vm.startPrank(lp);
        pair.transfer(address(pair), lpBal / 2);
        vm.expectRevert(ReentrancyGuard.ReentrancyGuardReentrantCall.selector);
        pair.burn(lp);
        vm.stopPrank();
    }

    function _seedLiquidity() internal {
        vm.startPrank(lp);
        token0.transfer(address(pair), 1_000 ether);
        token1.transfer(address(pair), 1_000 ether);
        pair.mint(lp);
        vm.stopPrank();
    }
}
