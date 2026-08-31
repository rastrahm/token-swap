// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {ITokenSwapPair} from "./interfaces/ITokenSwapPair.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";

/**
 * @title TokenSwapPair
 * @notice Par AMM de producto constante (`x * y = k`).
 * @dev Fase 1: stub desplegable para tests TDD (rojo). Lógica en fases 2–5.
 */
contract TokenSwapPair is ITokenSwapPair, ERC20, ReentrancyGuard {
    /// @inheritdoc ITokenSwapPair
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    /// @inheritdoc ITokenSwapPair
    address public immutable factory;

    /// @inheritdoc ITokenSwapPair
    address public immutable token0;

    /// @inheritdoc ITokenSwapPair
    address public immutable token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    /// @inheritdoc ITokenSwapPair
    uint256 public price0CumulativeLast;

    /// @inheritdoc ITokenSwapPair
    uint256 public price1CumulativeLast;

    /**
     * @notice Despliega el par con factory y tokens ordenados (`token0 < token1`).
     * @param factory_ Dirección de la factory (o el test contract en fase 1).
     * @param token0_ Token con dirección menor.
     * @param token1_ Token con dirección mayor.
     */
    constructor(address factory_, address token0_, address token1_) ERC20("TokenSwap LP", "TSLP") {
        if (factory_ == address(0) || token0_ == address(0) || token1_ == address(0)) {
            revert ZeroAddress();
        }
        factory = factory_;
        token0 = token0_;
        token1 = token1_;
    }

    /// @inheritdoc ITokenSwapPair
    function getReserves()
        external
        view
        returns (uint112 reserve0_, uint112 reserve1_, uint32 blockTimestampLast_)
    {
        reserve0_ = reserve0;
        reserve1_ = reserve1;
        blockTimestampLast_ = blockTimestampLast;
    }

    /// @inheritdoc ITokenSwapPair
    /// @dev Stub fase 1 — implementar en fase 3.
    function mint(address) external nonReentrant returns (uint256 liquidity) {
        return 0;
    }

    /// @inheritdoc ITokenSwapPair
    /// @dev Stub fase 1 — implementar en fase 5.
    function burn(address) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        return (0, 0);
    }

    /// @inheritdoc ITokenSwapPair
    /// @dev Stub fase 1 — implementar en fase 4.
    function swap(uint256, uint256, address, bytes calldata) external nonReentrant {}

    /// @inheritdoc ITokenSwapPair
    /// @dev Stub fase 1 — implementar en fase 5.
    function skim(address) external {}

    /// @inheritdoc ITokenSwapPair
    /// @dev Stub fase 1 — implementar en fase 2 (`_update`).
    function sync() external {}
}
