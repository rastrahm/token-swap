import { formatEther, parseEther } from "ethers";

/**
 * Acorta una address para UI.
 */
export function shortAddress(address: string): string {
  if (address.length < 10) return address;
  return `${address.slice(0, 6)}…${address.slice(-4)}`;
}

/**
 * Formatea wei a tokens legibles (18 decimales).
 */
export function formatTokens(wei: bigint | string): string {
  const n = formatEther(wei);
  const num = Number(n);
  if (num >= 1_000_000) return `${(num / 1_000_000).toFixed(2)}M`;
  if (num >= 1_000) return `${(num / 1_000).toFixed(2)}k`;
  if (num >= 1) return num.toFixed(4);
  return num.toPrecision(4);
}

/**
 * Parsea input de usuario a wei.
 */
export function parseTokenInput(amount: string): bigint {
  return parseEther(amount.trim() || "0");
}

/**
 * Deadline Unix para el router (+1 hora).
 */
export function routerDeadline(): bigint {
  return BigInt(Math.floor(Date.now() / 1000) + 3600);
}

/**
 * Output esperado con fee 0.3% (997/1000).
 */
export function getAmountOut(amountIn: bigint, reserveIn: bigint, reserveOut: bigint): bigint {
  if (amountIn <= 0n || reserveIn <= 0n || reserveOut <= 0n) return 0n;
  const withFee = amountIn * 997n;
  return (withFee * reserveOut) / (reserveIn * 1000n + withFee);
}

/**
 * Mínimo output tras slippage en bps.
 */
export function applySlippage(amountOut: bigint, slippageBps: number): bigint {
  return (amountOut * BigInt(10_000 - slippageBps)) / 10_000n;
}
