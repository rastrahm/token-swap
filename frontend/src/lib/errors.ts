import { formatEther, Interface } from "ethers";
import { erc20Abi, pairAbi, routerAbi } from "@/lib/contracts";

const REVERT_IFACE = new Interface([...routerAbi, ...erc20Abi, ...pairAbi]);

type EthersLikeError = {
  shortMessage?: string;
  reason?: string;
  message?: string;
  data?: unknown;
  info?: { error?: { data?: unknown } };
  error?: { data?: unknown };
};

/**
 * Busca datos de revert anidados (ethers / MetaMask RPC).
 */
function extractRevertData(err: unknown): string | null {
  if (!err || typeof err !== "object") return null;
  const e = err as EthersLikeError;
  const candidates = [e.data, e.info?.error?.data, e.error?.data];
  for (const value of candidates) {
    if (typeof value === "string" && value.startsWith("0x") && value.length >= 10) {
      return value;
    }
  }
  return null;
}

/**
 * Traduce custom errors del router / ERC-20 a mensajes legibles.
 */
function decodeRevertData(data: string): string | null {
  try {
    const parsed = REVERT_IFACE.parseError(data);
    if (!parsed) return null;

    switch (parsed.name) {
      case "ERC20InsufficientAllowance":
        return `Aprobación insuficiente para el router (tenés ${formatEther(parsed.args.allowance as bigint)}, se necesitan ${formatEther(parsed.args.needed as bigint)}). Confirmá la transacción de approve en MetaMask antes de continuar.`;
      case "ERC20InsufficientBalance":
        return `Saldo insuficiente (tenés ${formatEther(parsed.args.balance as bigint)}, se necesitan ${formatEther(parsed.args.needed as bigint)}). Usá «Mint demo 10k» primero.`;
      case "SafeTransferFailed":
        return "La transferencia de tokens falló. Revisá saldo y aprobación al router.";
      case "InsufficientAAmount":
        return "Cantidad de token A insuficiente o desproporcionada respecto al pool.";
      case "InsufficientBAmount":
        return "Cantidad de token B insuficiente o desproporcionada respecto al pool.";
      case "InsufficientOutputAmount":
        return "El output del swap es menor al mínimo (slippage).";
      case "InsufficientLiquidity":
        return "Liquidez insuficiente en el pool.";
      case "InvalidPath":
        return "Par de tokens inválido o inexistente en la factory.";
      case "Expired":
        return "La transacción expiró (deadline). Volvé a intentar.";
      case "ZeroAddress":
        return "Address cero no permitida.";
      case "InvalidK":
        return "Invariante K violada en el swap.";
      default:
        return `${parsed.name}()`;
    }
  } catch {
    return null;
  }
}

/**
 * Extrae mensaje legible de errores ethers / wallet.
 */
export function formatContractError(err: unknown): string {
  const data = extractRevertData(err);
  if (data) {
    const decoded = decodeRevertData(data);
    if (decoded) return decoded;
  }

  if (err instanceof Error || (err && typeof err === "object" && "shortMessage" in err)) {
    const nested = err as Error & EthersLikeError;
    if (nested.shortMessage?.includes("unknown custom error")) {
      return "La transacción fue revertida por el contrato. Si no hiciste «Mint demo 10k», hacelo primero y confirmá las dos aprobaciones (approve) en MetaMask.";
    }
    if (nested.shortMessage) return nested.shortMessage;
    if (nested.reason) return nested.reason;
    if (err instanceof Error) return nested.message;
  }
  return String(err);
}
