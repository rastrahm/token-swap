// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ITokenSwapPair} from "./interfaces/ITokenSwapPair.sol";
import {Math} from "./libraries/Math.sol";
import {UQ112x112} from "./libraries/UQ112x112.sol";
import {TokenSwapERC20} from "./TokenSwapERC20.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";

/**
 * @title TokenSwapPair
 * @notice Par AMM de producto constante (`x * y = k`).
 * @dev Fase 3: `mint` (primer depósito + subsequent + MINIMUM_LIQUIDITY).
 *      `swap`/`burn`/`skim` siguen stub (fases 4–5). `_update` TWAP desde fase 2.
 */
contract TokenSwapPair is ITokenSwapPair, TokenSwapERC20, ReentrancyGuard {
    using UQ112x112 for uint224;

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

    /// @inheritdoc ITokenSwapPair
    /// @dev Stub — implementar en fase 4.
    function swap(uint256, uint256, address, bytes calldata) external nonReentrant {}

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
