// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {MockERC20} from "../../src/mocks/MockERC20.sol";
import {ITokenSwapPair} from "../../src/interfaces/ITokenSwapPair.sol";

/**
 * @title MockERC20Reentrant
 * @notice ERC-20 de prueba que reentra en `mint`/`swap`/`burn` del par durante `transfer`.
 * @dev Dispara el hook al recibir tokens del par (`msg.sender == pair`) o al depositar en el par.
 */
contract MockERC20Reentrant is MockERC20 {
    enum Attack {
        None,
        ReenterMint,
        ReenterSwap,
        ReenterBurn
    }

    ITokenSwapPair public pair;
    Attack public attack;
    address public attacker;
    uint256 public swapAmountOut;

    constructor(string memory name_, string memory symbol_) MockERC20(name_, symbol_) {}

    function configure(ITokenSwapPair pair_, Attack attack_, address attacker_, uint256 swapAmountOut_) external {
        pair = pair_;
        attack = attack_;
        attacker = attacker_;
        swapAmountOut = swapAmountOut_;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        bool ok = super.transfer(to, amount);
        if (!ok || address(pair) == address(0) || attack == Attack.None) {
            return ok;
        }

        if (msg.sender == address(pair)) {
            _reenter();
        } else if (to == address(pair)) {
            _reenter();
        }
        return ok;
    }

    function _reenter() internal {
        if (attack == Attack.ReenterMint) {
            pair.mint(attacker);
        } else if (attack == Attack.ReenterSwap) {
            if (address(this) == pair.token0()) {
                pair.swap(0, swapAmountOut, attacker, "");
            } else {
                pair.swap(swapAmountOut, 0, attacker, "");
            }
        } else if (attack == Attack.ReenterBurn) {
            pair.burn(attacker);
        }
    }
}
