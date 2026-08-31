// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {ITokenSwapFactory} from "../src/interfaces/ITokenSwapFactory.sol";
import {ITokenSwapPair} from "../src/interfaces/ITokenSwapPair.sol";
import {ITokenSwapRouter} from "../src/interfaces/ITokenSwapRouter.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

/**
 * @title Phase0ScaffoldTest
 * @notice Smoke de scaffold: interfaces compilables, ERC-20 mock y config Foundry.
 */
contract Phase0ScaffoldTest is Test {
    function test_pairInterfaceId_isNonZero() public pure {
        assertTrue(type(ITokenSwapPair).interfaceId != bytes4(0));
    }

    function test_factoryInterfaceId_isNonZero() public pure {
        assertTrue(type(ITokenSwapFactory).interfaceId != bytes4(0));
    }

    function test_routerInterfaceId_isNonZero() public pure {
        assertTrue(type(ITokenSwapRouter).interfaceId != bytes4(0));
    }

    function test_mockErc20_mints() public {
        MockERC20 token = new MockERC20("Token A", "TKA");
        token.mint(address(this), 1e18);
        assertEq(token.balanceOf(address(this)), 1e18);
        assertEq(token.decimals(), 18);
    }

    function test_pairCustomErrors_selectorsAreDistinct() public pure {
        bytes4 a = ITokenSwapPair.InsufficientOutputAmount.selector;
        bytes4 b = ITokenSwapPair.InsufficientLiquidity.selector;
        bytes4 c = ITokenSwapPair.InsufficientInputAmount.selector;
        bytes4 d = ITokenSwapPair.InvalidK.selector;
        bytes4 e = ITokenSwapPair.ZeroAddress.selector;
        assertTrue(a != b && a != c && a != d && a != e);
        assertTrue(b != c && b != d && b != e);
        assertTrue(c != d && c != e && d != e);
    }
}
