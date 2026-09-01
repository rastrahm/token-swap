// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {MockERC20} from "../src/mocks/MockERC20.sol";
import {TokenSwapFactory} from "../src/TokenSwapFactory.sol";
import {TokenSwapRouter} from "../src/TokenSwapRouter.sol";

/**
 * @title Deploy
 * @notice Deploy local de Factory + Router + tokens demo + liquidez inicial para la UI.
 * @dev `forge script script/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast`
 */
contract Deploy is Script {
    uint256 internal constant SEED_LIQUIDITY = 10_000 ether;
    uint256 internal constant MINT_AMOUNT = 1_000_000 ether;

    function run() external {
        uint256 pk = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        address deployer = vm.addr(pk);

        vm.startBroadcast(pk);

        MockERC20 tokenA = new MockERC20("Alpha Token", "ALPHA");
        MockERC20 tokenB = new MockERC20("Beta Token", "BETA");

        TokenSwapFactory factory = new TokenSwapFactory();
        TokenSwapRouter router = new TokenSwapRouter(address(factory));

        (address token0, address token1) =
            address(tokenA) < address(tokenB) ? (address(tokenA), address(tokenB)) : (address(tokenB), address(tokenA));

        address pair = factory.createPair(token0, token1);

        tokenA.mint(deployer, MINT_AMOUNT);
        tokenB.mint(deployer, MINT_AMOUNT);

        IERC20(token0).approve(address(router), type(uint256).max);
        IERC20(token1).approve(address(router), type(uint256).max);

        router.addLiquidity(
            token0,
            token1,
            SEED_LIQUIDITY,
            SEED_LIQUIDITY,
            0,
            0,
            deployer,
            block.timestamp + 1 days
        );

        vm.stopBroadcast();

        console2.log("TokenA", address(tokenA));
        console2.log("TokenB", address(tokenB));
        console2.log("Token0", token0);
        console2.log("Token1", token1);
        console2.log("Factory", address(factory));
        console2.log("Router", address(router));
        console2.log("Pair", pair);
        console2.log("Deployer", deployer);
    }
}
