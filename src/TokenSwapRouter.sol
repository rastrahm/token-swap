// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ITokenSwapFactory} from "./interfaces/ITokenSwapFactory.sol";
import {ITokenSwapPair} from "./interfaces/ITokenSwapPair.sol";
import {ITokenSwapRouter} from "./interfaces/ITokenSwapRouter.sol";

/**
 * @title TokenSwapRouter
 * @notice Router v1: liquidez y swap directo (path de 2 tokens) con slippage y deadline.
 */
contract TokenSwapRouter is ITokenSwapRouter {
    using SafeERC20 for IERC20;

    /// @inheritdoc ITokenSwapRouter
    address public immutable factory;

    /**
     * @notice Despliega el router apuntando a una factory.
     * @param factory_ Dirección de `TokenSwapFactory`.
     */
    constructor(address factory_) {
        if (factory_ == address(0)) {
            revert ZeroAddress();
        }
        factory = factory_;
    }

    modifier ensure(uint256 deadline) {
        if (block.timestamp > deadline) {
            revert Expired();
        }
        _;
    }

    /// @inheritdoc ITokenSwapRouter
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB)
        external
        pure
        returns (uint256 amountB)
    {
        amountB = _quote(amountA, reserveA, reserveB);
    }

    function _quote(uint256 amountA, uint256 reserveA, uint256 reserveB)
        private
        pure
        returns (uint256 amountB)
    {
        if (amountA == 0) {
            revert InsufficientOutputAmount();
        }
        if (reserveA == 0 || reserveB == 0) {
            revert ITokenSwapPair.InsufficientLiquidity();
        }
        amountB = (amountA * reserveB) / reserveA;
    }

    /// @inheritdoc ITokenSwapRouter
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut)
    {
        amountOut = _getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        private
        pure
        returns (uint256 amountOut)
    {
        if (amountIn == 0) {
            revert InsufficientOutputAmount();
        }
        if (reserveIn == 0 || reserveOut == 0) {
            revert ITokenSwapPair.InsufficientLiquidity();
        }
        uint256 amountInWithFee = amountIn * 997;
        amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
    }

    /// @inheritdoc ITokenSwapRouter
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts)
    {
        if (path.length != 2) {
            revert InvalidPath();
        }
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = _getAmountOutPair(path[0], path[1], amountIn);
    }

    /// @inheritdoc ITokenSwapRouter
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        if (to == address(0)) {
            revert ZeroAddress();
        }
        return _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) private returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) =
            _quoteLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);

        address pair = _pairFor(tokenA, tokenB);
        _transferFrom(tokenA, pair, amountA);
        _transferFrom(tokenB, pair, amountB);
        liquidity = ITokenSwapPair(pair).mint(to);
    }

    function _transferFrom(address token, address to, uint256 amount) private {
        IERC20(token).safeTransferFrom(msg.sender, to, amount);
    }

    /// @inheritdoc ITokenSwapRouter
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        if (to == address(0)) {
            revert ZeroAddress();
        }

        address pair = _pairFor(tokenA, tokenB);
        IERC20(pair).safeTransferFrom(msg.sender, pair, liquidity);

        (uint256 amount0, uint256 amount1) = ITokenSwapPair(pair).burn(to);
        (address token0,) = _sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);

        if (amountA < amountAMin) {
            revert InsufficientAAmount();
        }
        if (amountB < amountBMin) {
            revert InsufficientBAmount();
        }
    }

    /// @inheritdoc ITokenSwapRouter
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        if (path.length != 2) {
            revert InvalidPath();
        }
        if (to == address(0)) {
            revert ZeroAddress();
        }

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = _getAmountOutPair(path[0], path[1], amountIn);
        if (amounts[1] < amountOutMin) {
            revert InsufficientOutputAmount();
        }

        address pair = _pairFor(path[0], path[1]);
        IERC20(path[0]).safeTransferFrom(msg.sender, pair, amountIn);

        (address token0,) = _sortTokens(path[0], path[1]);
        (uint256 amount0Out, uint256 amount1Out) =
            path[0] == token0 ? (uint256(0), amounts[1]) : (amounts[1], uint256(0));
        ITokenSwapPair(pair).swap(amount0Out, amount1Out, to, "");
    }

    /**
     * @notice Calcula cantidades óptimas de liquidez según reservas actuales.
     */
    function _quoteLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) private view returns (uint256 amountA, uint256 amountB) {
        if (amountADesired == 0 && amountBDesired == 0) {
            revert InsufficientAAmount();
        }

        (uint256 reserveA, uint256 reserveB) = _getReserves(tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            return (amountA, amountB);
        }

        uint256 amountBOptimal = _quote(amountADesired, reserveA, reserveB);
        if (amountBOptimal <= amountBDesired) {
            if (amountBOptimal < amountBMin) {
                revert InsufficientBAmount();
            }
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint256 amountAOptimal = _quote(amountBDesired, reserveB, reserveA);
            if (amountAOptimal > amountADesired) {
                revert InsufficientAAmount();
            }
            if (amountAOptimal < amountAMin) {
                revert InsufficientAAmount();
            }
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }

    function _getAmountOutPair(address tokenIn, address tokenOut, uint256 amountIn)
        private
        view
        returns (uint256 amountOut)
    {
        (uint256 reserveIn, uint256 reserveOut) = _getReserves(tokenIn, tokenOut);
        amountOut = _getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function _getReserves(address tokenA, address tokenB)
        private
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        address pair = _pairFor(tokenA, tokenB);
        (address token0,) = _sortTokens(tokenA, tokenB);
        (uint112 reserve0, uint112 reserve1,) = ITokenSwapPair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function _pairFor(address tokenA, address tokenB) private view returns (address pair) {
        pair = ITokenSwapFactory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            revert InvalidPath();
        }
    }

    function _sortTokens(address tokenA, address tokenB)
        private
        pure
        returns (address token0, address token1)
    {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}
