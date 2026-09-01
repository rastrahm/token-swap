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
 * @title TokenSwapGasTest
 * @notice Baseline de gas para `forge snapshot` y `doc/GAS.md` (Fase 8).
 */
contract TokenSwapGasTest is Test {
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

        token0.mint(lp, 10_000 ether);
        token1.mint(lp, 10_000 ether);
        token0.mint(trader, 10_000 ether);
        token1.mint(trader, 10_000 ether);
    }

    function testGas_createPair() public {
        MockERC20 tA = new MockERC20("C", "C");
        MockERC20 tB = new MockERC20("D", "D");
        factory.createPair(address(tA), address(tB));
    }

    function testGas_firstMint() public {
        vm.startPrank(lp);
        token0.approve(address(router), 1_000 ether);
        token1.approve(address(router), 1_000 ether);
        router.addLiquidity(
            address(token0), address(token1), 1_000 ether, 1_000 ether, 0, 0, lp, block.timestamp + 1 hours
        );
        vm.stopPrank();
    }

    function testGas_subsequentMint() public {
        _seedLiquidity();
        vm.startPrank(lp);
        token0.approve(address(router), 100 ether);
        token1.approve(address(router), 100 ether);
        router.addLiquidity(address(token0), address(token1), 100 ether, 100 ether, 0, 0, lp, block.timestamp + 1 hours);
        vm.stopPrank();
    }

    function testGas_swap() public {
        _seedLiquidity();
        uint256 amountIn = 10 ether;
        uint256[] memory expected = router.getAmountsOut(amountIn, _path(address(token0), address(token1)));

        vm.startPrank(trader);
        token0.approve(address(router), amountIn);
        router.swapExactTokensForTokens(
            amountIn, 0, _path(address(token0), address(token1)), trader, block.timestamp + 1 hours
        );
        vm.stopPrank();

        assertGt(expected[1], 0);
    }

    function testGas_burn() public {
        _seedLiquidity();
        uint256 lpBal = IERC20(address(pair)).balanceOf(lp);

        vm.startPrank(lp);
        IERC20(address(pair)).approve(address(router), lpBal / 2);
        router.removeLiquidity(address(token0), address(token1), lpBal / 2, 0, 0, lp, block.timestamp + 1 hours);
        vm.stopPrank();
    }

    function testGas_skim() public {
        _seedLiquidity();
        token0.mint(address(pair), 1 ether);
        pair.skim(lp);
    }

    function testGas_sync() public {
        _seedLiquidity();
        token0.mint(address(pair), 1 ether);
        pair.sync();
    }

    function _seedLiquidity() internal {
        vm.startPrank(lp);
        token0.approve(address(router), 1_000 ether);
        token1.approve(address(router), 1_000 ether);
        router.addLiquidity(
            address(token0), address(token1), 1_000 ether, 1_000 ether, 0, 0, lp, block.timestamp + 1 hours
        );
        vm.stopPrank();
    }

    function _path(address tokenIn, address tokenOut) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
    }
}
