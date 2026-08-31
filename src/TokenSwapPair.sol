// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ITokenSwapPair} from "./interfaces/ITokenSwapPair.sol";
import {Math} from "./libraries/Math.sol";
import {UQ112x112} from "./libraries/UQ112x112.sol";
import {TokenSwapERC20} from "./TokenSwapERC20.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";

/**
 * @title TokenSwapPair
 * @notice Par AMM de producto constante (`x * y = k`).
 * @dev Fase 4: `swap` con fee 0.3%, K-check y `nonReentrant`.
 *      `burn`/`skim` siguen stub (fase 5).
 */
contract TokenSwapPair is ITokenSwapPair, TokenSwapERC20, ReentrancyGuard {
    using UQ112x112 for uint224;
    using SafeERC20 for IERC20;

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
     * @param factory_ Dirección de la factory (o el test contract en fases tempranas).
     * @param token0_ Token con dirección menor.
     * @param token1_ Token con dirección mayor.
     */
    constructor(address factory_, address token0_, address token1_) {
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

    /**
     * @inheritdoc ITokenSwapPair
     * @dev Primer mint: `sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY` (lock a `address(0)`).
     *      Subsequent: `min(amount0 * totalSupply / reserve0, amount1 * totalSupply / reserve1)`.
     */
    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        uint112 reserve0_ = reserve0;
        uint112 reserve1_ = reserve1;
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0_;
        uint256 amount1 = balance1 - reserve1_;

        uint256 supply = totalSupply;
        if (supply == 0) {
            uint256 root = Math.sqrt(amount0 * amount1);
            if (root <= MINIMUM_LIQUIDITY) {
                revert InsufficientLiquidity();
            }
            liquidity = root - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min((amount0 * supply) / reserve0_, (amount1 * supply) / reserve1_);
        }
        if (liquidity == 0) {
            revert InsufficientLiquidity();
        }
        _mint(to, liquidity);

        _update(balance0, balance1, reserve0_, reserve1_);
        emit Mint(msg.sender, amount0, amount1);
    }

    /// @inheritdoc ITokenSwapPair
    /// @dev Stub — implementar en fase 5.
    function burn(address) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        return (0, 0);
    }

    /**
     * @inheritdoc ITokenSwapPair
     * @dev Optimistic transfer → medir `amountIn` → fee 0.3% embebido en K-check
     *      (`balanceAdj = balance*1000 - amountIn*3` ≥ `r0*r1*1000²`).
     *      v1: `data` no dispara callback (flash swap fuera de alcance).
     */
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata)
        external
        nonReentrant
    {
        if (amount0Out == 0 && amount1Out == 0) {
            revert InsufficientOutputAmount();
        }

        uint112 reserve0_ = reserve0;
        uint112 reserve1_ = reserve1;
        if (amount0Out >= reserve0_ || amount1Out >= reserve1_) {
            revert InsufficientLiquidity();
        }

        uint256 balance0;
        uint256 balance1;
        {
            address token0_ = token0;
            address token1_ = token1;
            if (to == token0_ || to == token1_) {
                revert InvalidTo();
            }
            if (amount0Out > 0) {
                IERC20(token0_).safeTransfer(to, amount0Out);
            }
            if (amount1Out > 0) {
                IERC20(token1_).safeTransfer(to, amount1Out);
            }
            balance0 = IERC20(token0_).balanceOf(address(this));
            balance1 = IERC20(token1_).balanceOf(address(this));
        }

        uint256 amount0In = balance0 > reserve0_ - amount0Out ? balance0 - (reserve0_ - amount0Out) : 0;
        uint256 amount1In = balance1 > reserve1_ - amount1Out ? balance1 - (reserve1_ - amount1Out) : 0;
        if (amount0In == 0 && amount1In == 0) {
            revert InsufficientInputAmount();
        }

        {
            uint256 balance0Adjusted = balance0 * 1000 - amount0In * 3;
            uint256 balance1Adjusted = balance1 * 1000 - amount1In * 3;
            if (balance0Adjusted * balance1Adjusted < uint256(reserve0_) * uint256(reserve1_) * 1_000_000) {
                revert InvalidK();
            }
        }

        _update(balance0, balance1, reserve0_, reserve1_);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /// @inheritdoc ITokenSwapPair
    /// @dev Stub — implementar en fase 5.
    function skim(address) external {}

    /// @inheritdoc ITokenSwapPair
    function sync() external {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    /**
     * @notice Actualiza reservas y acumuladores TWAP.
     * @dev Acumula precio solo si `timeElapsed > 0` y ambas reservas previas son > 0.
     * @param balance0 Balance actual de token0 en el par.
     * @param balance1 Balance actual de token1 en el par.
     * @param reserve0_ Reserva token0 previa.
     * @param reserve1_ Reserva token1 previa.
     */
    function _update(uint256 balance0, uint256 balance1, uint112 reserve0_, uint112 reserve1_) private {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max) {
            revert Overflow();
        }

        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed;
        unchecked {
            // Overflow uint32 intencional (wrap de timestamp), igual que Uniswap V2.
            timeElapsed = blockTimestamp - blockTimestampLast;
        }

        if (timeElapsed > 0 && reserve0_ != 0 && reserve1_ != 0) {
            unchecked {
                // + puede overflow; es el diseño del acumulador TWAP.
                price0CumulativeLast += uint256(UQ112x112.encode(reserve1_).uqdiv(reserve0_)) * timeElapsed;
                price1CumulativeLast += uint256(UQ112x112.encode(reserve0_).uqdiv(reserve1_)) * timeElapsed;
            }
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;

        emit Sync(reserve0, reserve1);
    }
}
