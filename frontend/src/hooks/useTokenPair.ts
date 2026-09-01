"use client";

import { useCallback, useEffect, useState } from "react";
import { Contract } from "ethers";
import { createReadProvider, factoryAbi } from "@/lib/contracts";
import type { PublicEnv } from "@/lib/env";
import {
  clearStoredTokenPair,
  loadStoredTokenPair,
  saveStoredTokenPair,
  tokenPairSchema,
  type TokenPairConfig,
  type TokenPairInput,
} from "@/lib/tokenPair";

const ZERO_PAIR = "0x0000000000000000000000000000000000000000";

function defaultsFromEnv(env: PublicEnv): TokenPairConfig {
  return {
    tokenA: env.NEXT_PUBLIC_TOKEN_A_ADDRESS,
    tokenB: env.NEXT_PUBLIC_TOKEN_B_ADDRESS,
    pair: env.NEXT_PUBLIC_PAIR_ADDRESS,
  };
}

/**
 * Resuelve el par en la factory y valida que exista.
 */
async function resolvePair(env: PublicEnv, tokens: TokenPairInput): Promise<string> {
  const provider = createReadProvider(env.NEXT_PUBLIC_RPC_URL);
  const factory = new Contract(env.NEXT_PUBLIC_FACTORY_ADDRESS, factoryAbi, provider);
  const pair = (await factory.getPair(tokens.tokenA, tokens.tokenB)) as string;
  if (!pair || pair.toLowerCase() === ZERO_PAIR) {
    throw new Error("No existe par para esos tokens. Creá uno con la factory o usá el deploy demo.");
  }
  return pair;
}

/**
 * Hook: tokens ALPHA/BETA editables con persistencia y resolución de `pair`.
 */
export function useTokenPair(env: PublicEnv | null) {
  const [config, setConfig] = useState<TokenPairConfig | null>(null);
  const [draftA, setDraftA] = useState("");
  const [draftB, setDraftB] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const applyTokens = useCallback(
    async (tokens: TokenPairInput, persist: boolean) => {
      if (!env) return;
      const parsed = tokenPairSchema.safeParse(tokens);
      if (!parsed.success) {
        setError(parsed.error.issues[0]?.message ?? "Addresses inválidas");
        return;
      }
      setBusy(true);
      setError(null);
      try {
        const pair = await resolvePair(env, parsed.data);
        const next: TokenPairConfig = { ...parsed.data, pair };
        setConfig(next);
        setDraftA(next.tokenA);
        setDraftB(next.tokenB);
        if (persist) saveStoredTokenPair(parsed.data);
      } catch (err) {
        setError(err instanceof Error ? err.message : String(err));
      } finally {
        setBusy(false);
      }
    },
    [env],
  );

  useEffect(() => {
    if (!env) return;

    const defaults = defaultsFromEnv(env);
    setConfig(defaults);
    setDraftA(defaults.tokenA);
    setDraftB(defaults.tokenB);
    setError(null);

    const stored = loadStoredTokenPair();
    if (!stored) return;

    setDraftA(stored.tokenA);
    setDraftB(stored.tokenB);
    void applyTokens(stored, false);
    // Solo al montar / cambiar env; applyTokens estable mientras env no cambie.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [env]);

  const applyDraft = useCallback(() => {
    void applyTokens({ tokenA: draftA.trim(), tokenB: draftB.trim() }, true);
  }, [applyTokens, draftA, draftB]);

  const swapTokens = useCallback(() => {
    const next = { tokenA: draftB.trim(), tokenB: draftA.trim() };
    setDraftA(next.tokenA);
    setDraftB(next.tokenB);
    void applyTokens(next, true);
  }, [applyTokens, draftA, draftB]);

  const resetToDeploy = useCallback(() => {
    if (!env) return;
    clearStoredTokenPair();
    const d = defaultsFromEnv(env);
    setDraftA(d.tokenA);
    setDraftB(d.tokenB);
    setConfig(d);
    setError(null);
  }, [env]);

  return {
    config,
    draftA,
    draftB,
    setDraftA,
    setDraftB,
    busy,
    error,
    applyDraft,
    swapTokens,
    resetToDeploy,
  };
}
