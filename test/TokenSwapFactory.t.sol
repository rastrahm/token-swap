// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {ITokenSwapFactory} from "../src/interfaces/ITokenSwapFactory.sol";
import {ITokenSwapPair} from "../src/interfaces/ITokenSwapPair.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {TokenSwapFactory} from "../src/TokenSwapFactory.sol";

/**
 * @title TokenSwapFactoryTest
 * @notice Fase 6: creación de pares, orden de tokens y unicidad.
 */
contract TokenSwapFactoryTest is Test {
    TokenSwapFactory internal factory;
    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    function setUp() public {
        factory = new TokenSwapFactory();
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");
    }

    function test_createPair_ordersTokensAndRegistersBidirectional() public {
        (address token0, address token1) =
            address(tokenA) < address(tokenB) ? (address(tokenA), address(tokenB)) : (address(tokenB), address(tokenA));

        vm.expectEmit(true, true, false, false, address(factory));
        emit ITokenSwapFactory.PairCreated(token0, token1, address(0), 0);

        address pair = factory.createPair(address(tokenA), address(tokenB));

        assertEq(factory.getPair(address(tokenA), address(tokenB)), pair);
        assertEq(factory.getPair(address(tokenB), address(tokenA)), pair);
        assertEq(factory.allPairs(0), pair);
        assertEq(factory.allPairsLength(), 1);

        assertEq(ITokenSwapPair(pair).factory(), address(factory));
        assertEq(ITokenSwapPair(pair).token0(), token0);
        assertEq(ITokenSwapPair(pair).token1(), token1);
    }

    function test_createPair_revertsIdenticalAddresses() public {
        vm.expectRevert(ITokenSwapFactory.IdenticalAddresses.selector);
        factory.createPair(address(tokenA), address(tokenA));
    }

    function test_createPair_revertsZeroAddress() public {
        vm.expectRevert(ITokenSwapFactory.ZeroAddress.selector);
        factory.createPair(address(0), address(tokenB));
    }

    function test_createPair_revertsPairExists() public {
        factory.createPair(address(tokenA), address(tokenB));
        vm.expectRevert(ITokenSwapFactory.PairExists.selector);
        factory.createPair(address(tokenA), address(tokenB));
    }
}
