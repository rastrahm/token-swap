// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {Math} from "../src/libraries/Math.sol";

/**
 * @title MathTest
 * @notice Unit tests de `Math.sqrt` / `Math.min` (fase 2).
 */
contract MathTest is Test {
    function test_sqrt_zero() public pure {
        assertEq(Math.sqrt(0), 0);
    }

    function test_sqrt_one() public pure {
        assertEq(Math.sqrt(1), 1);
    }

    function test_sqrt_twoAndThree_floorToOne() public pure {
        assertEq(Math.sqrt(2), 1);
        assertEq(Math.sqrt(3), 1);
    }

    function test_sqrt_perfectSquares() public pure {
        assertEq(Math.sqrt(4), 2);
        assertEq(Math.sqrt(9), 3);
        assertEq(Math.sqrt(1e18 * 1e18), 1e18);
    }

    function test_sqrt_floorsNonPerfect() public pure {
        assertEq(Math.sqrt(10), 3);
        assertEq(Math.sqrt(15), 3);
        assertEq(Math.sqrt(16), 4);
    }

    function test_min() public pure {
        assertEq(Math.min(1, 2), 1);
        assertEq(Math.min(5, 5), 5);
        assertEq(Math.min(100, 7), 7);
    }
}
