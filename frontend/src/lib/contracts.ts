import { BrowserProvider, Contract, JsonRpcProvider, type Signer } from "ethers";
import factoryAbiJson from "../../abi/TokenSwapFactory.json";
import routerAbiJson from "../../abi/TokenSwapRouter.json";
import pairAbiJson from "../../abi/TokenSwapPair.json";
import erc20AbiJson from "../../abi/MockERC20.json";
import type { PublicEnv } from "./env";
import type { TokenPairConfig } from "./tokenPair";

export const factoryAbi = factoryAbiJson.abi;
export const routerAbi = routerAbiJson.abi;
export const pairAbi = pairAbiJson.abi;
export const erc20Abi = erc20AbiJson.abi;

export type AmmEnv = Pick<
  PublicEnv,
  "NEXT_PUBLIC_RPC_URL" | "NEXT_PUBLIC_FACTORY_ADDRESS" | "NEXT_PUBLIC_ROUTER_ADDRESS"
>;

/**
 * Provider de solo lectura hacia el RPC configurado.
 */
export function createReadProvider(rpcUrl: string): JsonRpcProvider {
  return new JsonRpcProvider(rpcUrl);
}

/**
 * Contratos de lectura (sin signer).
 */
export function createReadContracts(env: AmmEnv, tokens: TokenPairConfig, provider?: JsonRpcProvider) {
  if (!tokens?.pair || !tokens.tokenA || !tokens.tokenB) {
    throw new Error("Configuración de par incompleta");
  }
  const p = provider ?? createReadProvider(env.NEXT_PUBLIC_RPC_URL);
  return {
    provider: p,
    factory: new Contract(env.NEXT_PUBLIC_FACTORY_ADDRESS, factoryAbi, p),
    router: new Contract(env.NEXT_PUBLIC_ROUTER_ADDRESS, routerAbi, p),
    pair: new Contract(tokens.pair, pairAbi, p),
    tokenA: new Contract(tokens.tokenA, erc20Abi, p),
    tokenB: new Contract(tokens.tokenB, erc20Abi, p),
  };
}

/**
 * Contratos conectados a un signer (wallet).
 */
export function createWriteContracts(env: AmmEnv, tokens: TokenPairConfig, signer: Signer) {
  if (!tokens?.pair || !tokens.tokenA || !tokens.tokenB) {
    throw new Error("Configuración de par incompleta");
  }
  return {
    factory: new Contract(env.NEXT_PUBLIC_FACTORY_ADDRESS, factoryAbi, signer),
    router: new Contract(env.NEXT_PUBLIC_ROUTER_ADDRESS, routerAbi, signer),
    pair: new Contract(tokens.pair, pairAbi, signer),
    tokenA: new Contract(tokens.tokenA, erc20Abi, signer),
    tokenB: new Contract(tokens.tokenB, erc20Abi, signer),
  };
}

/**
 * Obtiene BrowserProvider desde `window.ethereum`.
 */
export function getBrowserProvider(): BrowserProvider {
  const eth = typeof window !== "undefined" ? window.ethereum : undefined;
  if (!eth) {
    throw new Error("No hay wallet inyectada (instala MetaMask u otra).");
  }
  return new BrowserProvider(eth);
}

declare global {
  interface Window {
    ethereum?: {
      request: (args: { method: string; params?: unknown[] }) => Promise<unknown>;
      on?: (event: string, handler: (...args: unknown[]) => void) => void;
      removeListener?: (event: string, handler: (...args: unknown[]) => void) => void;
    };
  }
}
