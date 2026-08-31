// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ReentrancyGuard
 * @notice Guardia de reentrada con storage transitorio (EIP-1153 / Cancun).
 * @dev Sin SSTORE permanente: más barato que el guard basado en estado. Slot dedicado vía hash.
 */
abstract contract ReentrancyGuard {
    /// @notice Llamada reentrante detectada.
    error ReentrancyGuardReentrantCall();

    /// @dev Slot transient único (no colisiona con storage permanente del contrato).
    uint256 private constant _REENTRANCY_GUARD_SLOT =
        0x5e1a1e8a0c2e7b9d4f6a8c0e2b4d6f8193a5c7e9b1d3f5072948675a3c1e0b2d;

    /**
     * @notice Impide reentrada mientras la función protegida está en ejecución.
     * @dev `tstore`/`tload` (Cancun). Se hace `tstore(0)` explícito tras el cuerpo.
     */
    modifier nonReentrant() {
        assembly ("memory-safe") {
            if tload(_REENTRANCY_GUARD_SLOT) {
                mstore(0x00, 0x3ee5aeb5) // ReentrancyGuardReentrantCall()
                revert(0x1c, 0x04)
            }
            tstore(_REENTRANCY_GUARD_SLOT, 1)
        }
        _;
        assembly ("memory-safe") {
            tstore(_REENTRANCY_GUARD_SLOT, 0)
        }
    }
}
