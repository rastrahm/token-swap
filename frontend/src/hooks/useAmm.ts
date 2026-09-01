"use client";

import { useCallback, useEffect, useState } from "react";
import type { Signer, Contract } from "ethers";
import { MaxUint256, formatEther } from "ethers";
import { createReadContracts, createWriteContracts, type AmmEnv } from "@/lib/contracts";
import { formatContractError } from "@/lib/errors";
import type { TokenPairConfig } from "@/lib/tokenPair";
import { applySlippage, getAmountOut, parseTokenInput, routerDeadline } from "@/lib/format";

export type PoolSnapshot = {
  reserveA: bigint;
  reserveB: bigint;
  tokenAName: string;
  tokenASymbol: string;
  tokenBName: string;
  tokenBSymbol: string;
  lpBalance: bigint;
  balanceA: bigint;
  balanceB: bigint;
};

const ZERO = 0n;

/**
 * Lectura/escritura del AMM vía Router + par de tokens configurable.
 */
export function useAmm(
  env: AmmEnv | null,
  tokens: TokenPairConfig | null,
  address: string | null,
  signer: Signer | null,
) {
  const [snap, setSnap] = useState<PoolSnapshot>({
    reserveA: ZERO,
    reserveB: ZERO,
    tokenAName: "—",
    tokenASymbol: "A",
    tokenBName: "—",
    tokenBSymbol: "B",
    lpBalance: ZERO,
    balanceA: ZERO,
    balanceB: ZERO,
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!env || !tokens?.pair || !tokens.tokenA || !tokens.tokenB) return;
    try {
      const { pair, tokenA, tokenB } = createReadContracts(env, tokens);
    const [reserves, token0Addr, nameA, symA, nameB, symB] = await Promise.all([
      pair.getReserves() as Promise<[bigint, bigint, number]>,
      pair.token0() as Promise<string>,
      tokenA.name() as Promise<string>,
      tokenA.symbol() as Promise<string>,
      tokenB.name() as Promise<string>,
      tokenB.symbol() as Promise<string>,
    ]);

    const aIsToken0 = tokens.tokenA.toLowerCase() === token0Addr.toLowerCase();
    const reserveA = aIsToken0 ? reserves[0] : reserves[1];
    const reserveB = aIsToken0 ? reserves[1] : reserves[0];

    let lpBalance = ZERO;
    let balanceA = ZERO;
    let balanceB = ZERO;
    if (address) {
      [lpBalance, balanceA, balanceB] = await Promise.all([
        pair.balanceOf(address) as Promise<bigint>,
        tokenA.balanceOf(address) as Promise<bigint>,
        tokenB.balanceOf(address) as Promise<bigint>,
      ]);
    }

    setSnap({
      reserveA,
      reserveB,
      tokenAName: nameA,
      tokenASymbol: symA,
      tokenBName: nameB,
      tokenBSymbol: symB,
      lpBalance,
      balanceA,
      balanceB,
    });
    } catch {
      // Par o RPC aún no listos (p. ej. Anvil reiniciado).
    }
  }, [env, tokens, address]);

  useEffect(() => {
    void refresh();
    const id = setInterval(() => void refresh(), 12_000);
    return () => clearInterval(id);
  }, [refresh]);

  const runTx = useCallback(
    async (label: string, fn: () => Promise<unknown>) => {
      setBusy(true);
      setError(null);
      setStatus(`${label}…`);
      try {
        const tx = (await fn()) as { wait: () => Promise<unknown> };
        await tx.wait();
        setStatus(`${label} confirmado`);
        await refresh();
      } catch (err) {
        setError(formatContractError(err));
        setStatus(null);
      } finally {
        setBusy(false);
      }
    },
    [refresh],
  );

  const assertBalance = useCallback(async (token: Contract, amount: bigint, symbol: string) => {
    if (!address) throw new Error("Conectá la wallet");
    const balance = (await token.balanceOf(address)) as bigint;
    if (balance < amount) {
      throw new Error(
        `Saldo insuficiente de ${symbol}: tenés ${formatEther(balance)}, necesitás ${formatEther(amount)}. Usá «Mint demo 10k».`,
      );
    }
  }, [address]);

  const ensureAllowance = useCallback(
    async (token: Contract, amount: bigint, symbol: string) => {
      if (!env || !address || !signer) throw new Error("Conectá la wallet");
      const current = (await token.allowance(address, env.NEXT_PUBLIC_ROUTER_ADDRESS)) as bigint;
      if (current >= amount) return;
      setStatus(`Aprobá ${symbol} en MetaMask…`);
      const tx = await token.approve(env.NEXT_PUBLIC_ROUTER_ADDRESS, MaxUint256);
      await (tx as { wait: () => Promise<unknown> }).wait();
    },
    [env, address, signer],
  );

  const swapAforB = useCallback(
    async (amountInStr: string, slippageBps: number) => {
      if (!env || !signer || !tokens?.pair) return;
      const amountIn = parseTokenInput(amountInStr);
      const expected = getAmountOut(amountIn, snap.reserveA, snap.reserveB);
      const amountOutMin = applySlippage(expected, slippageBps);
      const { router, tokenA } = createWriteContracts(env, tokens, signer);
      await runTx("Swap", async () => {
        await assertBalance(tokenA, amountIn, snap.tokenASymbol);
        await ensureAllowance(tokenA, amountIn, snap.tokenASymbol);
        return router.swapExactTokensForTokens(
          amountIn,
          amountOutMin,
          [tokens.tokenA, tokens.tokenB],
          address,
          routerDeadline(),
        );
      });
    },
    [env, signer, tokens, snap, address, assertBalance, ensureAllowance, runTx],
  );

  const swapBforA = useCallback(
    async (amountInStr: string, slippageBps: number) => {
      if (!env || !signer || !tokens?.pair) return;
      const amountIn = parseTokenInput(amountInStr);
      const expected = getAmountOut(amountIn, snap.reserveB, snap.reserveA);
      const amountOutMin = applySlippage(expected, slippageBps);
      const { router, tokenB } = createWriteContracts(env, tokens, signer);
      await runTx("Swap", async () => {
        await assertBalance(tokenB, amountIn, snap.tokenBSymbol);
        await ensureAllowance(tokenB, amountIn, snap.tokenBSymbol);
        return router.swapExactTokensForTokens(
          amountIn,
          amountOutMin,
          [tokens.tokenB, tokens.tokenA],
          address,
          routerDeadline(),
        );
      });
    },
    [env, signer, tokens, snap, address, assertBalance, ensureAllowance, runTx],
  );

  const addLiquidity = useCallback(
    async (amountAStr: string, amountBStr: string) => {
      if (!env || !signer || !address || !tokens?.pair) return;
      const amountA = parseTokenInput(amountAStr);
      const amountB = parseTokenInput(amountBStr);
      const { router, tokenA, tokenB } = createWriteContracts(env, tokens, signer);
      await runTx("Añadir liquidez", async () => {
        await assertBalance(tokenA, amountA, snap.tokenASymbol);
        await assertBalance(tokenB, amountB, snap.tokenBSymbol);
        await ensureAllowance(tokenA, amountA, snap.tokenASymbol);
        await ensureAllowance(tokenB, amountB, snap.tokenBSymbol);
        return router.addLiquidity(tokens.tokenA, tokens.tokenB, amountA, amountB, 0, 0, address, routerDeadline());
      });
    },
    [env, signer, address, tokens, snap, assertBalance, ensureAllowance, runTx],
  );

  const removeLiquidity = useCallback(
    async (lpAmountStr: string) => {
      if (!env || !signer || !address || !tokens?.pair) return;
      const liquidity = parseTokenInput(lpAmountStr);
      const { router, pair } = createWriteContracts(env, tokens, signer);
      await runTx("Retirar liquidez", async () => {
        await ensureAllowance(pair, liquidity, "LP");
        return router.removeLiquidity(tokens.tokenA, tokens.tokenB, liquidity, 0, 0, address, routerDeadline());
      });
    },
    [env, signer, address, tokens, ensureAllowance, runTx],
  );

  const mintDemoTokens = useCallback(async () => {
    if (!env || !signer || !address || !tokens?.pair) return;
    const { tokenA, tokenB } = createWriteContracts(env, tokens, signer);
    const amount = parseTokenInput("10000");
    await runTx("Mint demo", async () => {
      const tx1 = await tokenA.mint(address, amount);
      await tx1.wait();
      const tx2 = await tokenB.mint(address, amount);
      return tx2;
    });
  }, [env, signer, address, tokens, runTx]);

  return {
    snap,
    busy,
    error,
    status,
    refresh,
    swapAforB,
    swapBforA,
    addLiquidity,
    removeLiquidity,
    mintDemoTokens,
  };
}
