import { z } from "zod";

const addressSchema = z
  .string()
  .regex(/^0x[a-fA-F0-9]{40}$/, "Debe ser address 0x + 40 hex");

/** Par de tokens ERC-20 del AMM. */
export const tokenPairSchema = z
  .object({
    tokenA: addressSchema,
    tokenB: addressSchema,
  })
  .refine((t) => t.tokenA.toLowerCase() !== t.tokenB.toLowerCase(), {
    message: "ALPHA y BETA deben ser distintos",
    path: ["tokenB"],
  });

export type TokenPairInput = z.infer<typeof tokenPairSchema>;

export type TokenPairConfig = TokenPairInput & {
  pair: string;
};

const STORAGE_KEY = "swap-token-pair";

/**
 * Lee el par guardado en localStorage (sin validar pair on-chain).
 */
export function loadStoredTokenPair(): TokenPairInput | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    const parsed = tokenPairSchema.safeParse(JSON.parse(raw));
    return parsed.success ? parsed.data : null;
  } catch {
    return null;
  }
}

/**
 * Persiste tokenA/tokenB en localStorage.
 */
export function saveStoredTokenPair(tokens: TokenPairInput): void {
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(tokens));
}

/**
 * Elimina override de tokens (vuelve al deploy en `.env.local`).
 */
export function clearStoredTokenPair(): void {
  window.localStorage.removeItem(STORAGE_KEY);
}
