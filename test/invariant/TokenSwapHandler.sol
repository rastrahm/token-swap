// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ITokenSwapPair} from "../../src/interfaces/ITokenSwapPair.sol";
import {TokenSwapRouter} from "../../src/TokenSwapRouter.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

/**
 * @title TokenSwapHandler
 * @notice Handler para invariantes: mint / swap / burn / warp / sync.
 */
contract TokenSwapHandler is Test {
    ITokenSwapPair public immutable pair;
    TokenSwapRouter public immutable router;
    MockERC20 public immutable token0;
    MockERC20 public immutable token1;

    address[] public actorsList;

    /// @notice Producto `reserve0 * reserve1` tras la última operación exitosa del handler.
    uint256 public ghostK;

    constructor(ITokenSwapPair pair_, TokenSwapRouter router_, MockERC20 token0_, MockERC20 token1_) {
        pair = pair_;
        router = router_;
        token0 = token0_;
        token1 = token1_;

        actorsList.push(makeAddr("actor0"));
        actorsList.push(makeAddr("actor1"));
        actorsList.push(makeAddr("actor2"));

        for (uint256 i = 0; i < actorsList.length; ++i) {
            token0.mint(actorsList[i], 1_000_000 ether);
            token1.mint(actorsList[i], 1_000_000 ether);
        }
    }

    function actors() external view returns (address[] memory) {
        return actorsList;
    }

    function mintLiquidity(uint256 actorSeed, uint256 amount0, uint256 amount1) external {
        address actor = actorsList[actorSeed % actorsList.length];
        amount0 = bound(amount0, 1 ether, 10_000 ether);
        amount1 = bound(amount1, 1 ether, 10_000 ether);

        vm.startPrank(actor);
        token0.approve(address(router), amount0);
        token1.approve(address(router), amount1);
        router.addLiquidity(address(token0), address(token1), amount0, amount1, 0, 0, actor, block.timestamp + 1 hours);
        vm.stopPrank();

        _syncGhostK();
    }

    function swapToken0For1(uint256 actorSeed, uint256 amountIn) external {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        if (r0 == 0 || r1 == 0) {
            return;
        }

        address actor = actorsList[actorSeed % actorsList.length];
        amountIn = bound(amountIn, 1, uint256(r0) / 20);
        if (amountIn == 0) {
            return;
        }

        uint256 kBefore = uint256(r0) * r1;
        uint256[] memory amounts = router.getAmountsOut(amountIn, _path(address(token0), address(token1)));
        if (amounts[1] == 0 || amounts[1] >= r1) {
            return;
        }

        vm.startPrank(actor);
        token0.approve(address(router), amountIn);
        router.swapExactTokensForTokens(
            amountIn, 0, _path(address(token0), address(token1)), actor, block.timestamp + 1 hours
        );
        vm.stopPrank();

        (uint112 r0After, uint112 r1After,) = pair.getReserves();
        uint256 kAfter = uint256(r0After) * r1After;
        assertGe(kAfter, kBefore, "swap must not decrease k");
        ghostK = kAfter;
    }

    function swapToken1For0(uint256 actorSeed, uint256 amountIn) external {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        if (r0 == 0 || r1 == 0) {
            return;
        }

        address actor = actorsList[actorSeed % actorsList.length];
        amountIn = bound(amountIn, 1, uint256(r1) / 20);
        if (amountIn == 0) {
            return;
        }

        uint256 kBefore = uint256(r0) * r1;
        uint256[] memory amounts = router.getAmountsOut(amountIn, _path(address(token1), address(token0)));
        if (amounts[1] == 0 || amounts[1] >= r0) {
            return;
        }

        vm.startPrank(actor);
        token1.approve(address(router), amountIn);
        router.swapExactTokensForTokens(
            amountIn, 0, _path(address(token1), address(token0)), actor, block.timestamp + 1 hours
        );
        vm.stopPrank();

        (uint112 r0After, uint112 r1After,) = pair.getReserves();
        uint256 kAfter = uint256(r0After) * r1After;
        assertGe(kAfter, kBefore, "swap must not decrease k");
        ghostK = kAfter;
    }

    function burnLiquidity(uint256 actorSeed, uint256 liquidityShare) external {
        address actor = actorsList[actorSeed % actorsList.length];
        uint256 lpBal = IERC20(address(pair)).balanceOf(actor);
        if (lpBal == 0) {
            return;
        }

        liquidityShare = bound(liquidityShare, 1, lpBal);

        vm.startPrank(actor);
        IERC20(address(pair)).approve(address(router), liquidityShare);
        router.removeLiquidity(address(token0), address(token1), liquidityShare, 0, 0, actor, block.timestamp + 1 hours);
        vm.stopPrank();

        _syncGhostK();
    }

    function warpTime(uint256 secs) external {
        secs = bound(secs, 1, 1 days);
        vm.warp(block.timestamp + secs);
    }

    function sync() external {
        pair.sync();
        _syncGhostK();
    }

    function _syncGhostK() internal {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        if (r0 > 0 && r1 > 0) {
            ghostK = uint256(r0) * r1;
        }
    }

    function _path(address tokenIn, address tokenOut) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
    }
}
