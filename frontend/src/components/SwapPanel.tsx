"use client";

import { useMemo, useState } from "react";
import type { PoolSnapshot } from "@/hooks/useAmm";
import { getAmountOut, parseTokenInput } from "@/lib/format";
import { swapFormSchema } from "@/lib/schemas";

type SwapPanelProps = {
  snap: PoolSnapshot;
  busy: boolean;
  connected: boolean;
  onSwapAforB: (amount: string, slippageBps: number) => void;
  onSwapBforA: (amount: string, slippageBps: number) => void;
};

/**
 * Panel de swap A ↔ B con slippage.
 */
export function SwapPanel({ snap, busy, connected, onSwapAforB, onSwapBforA }: SwapPanelProps) {
  const [direction, setDirection] = useState<"aToB" | "bToA">("aToB");
  const [amountIn, setAmountIn] = useState("1");
  const [slippage, setSlippage] = useState("50");
  const [formError, setFormError] = useState<string | null>(null);

  const estimate = useMemo(() => {
    try {
      const amt = parseTokenInput(amountIn);
      if (direction === "aToB") return getAmountOut(amt, snap.reserveA, snap.reserveB);
      return getAmountOut(amt, snap.reserveB, snap.reserveA);
    } catch {
      return 0n;
    }
  }, [amountIn, direction, snap.reserveA, snap.reserveB]);

  const submit = () => {
    const parsed = swapFormSchema.safeParse({ amountIn, slippageBps: Number(slippage) });
    if (!parsed.success) {
      setFormError(parsed.error.issues[0]?.message ?? "Datos inválidos");
      return;
    }
    setFormError(null);
    if (direction === "aToB") onSwapAforB(parsed.data.amountIn, parsed.data.slippageBps);
    else onSwapBforA(parsed.data.amountIn, parsed.data.slippageBps);
  };

  const inSym = direction === "aToB" ? snap.tokenASymbol : snap.tokenBSymbol;
  const outSym = direction === "aToB" ? snap.tokenBSymbol : snap.tokenASymbol;

  return (
    <section className="panel" aria-label="Swap">
      <h2 className="panel-title">Swap</h2>
      <div className="actions tab-row">
        <button type="button" className={`btn ${direction === "aToB" ? "btn-primary" : "btn-ghost"}`} onClick={() => setDirection("aToB")}>
          {snap.tokenASymbol} → {snap.tokenBSymbol}
        </button>
        <button type="button" className={`btn ${direction === "bToA" ? "btn-primary" : "btn-ghost"}`} onClick={() => setDirection("bToA")}>
          {snap.tokenBSymbol} → {snap.tokenASymbol}
        </button>
      </div>
      <label className="field">
        Cantidad ({inSym})
        <input aria-label="Cantidad de entrada" inputMode="decimal" value={amountIn} onChange={(e) => setAmountIn(e.target.value)} />
      </label>
      <label className="field">
        Slippage (bps)
        <input aria-label="Slippage en puntos básicos" inputMode="numeric" value={slippage} onChange={(e) => setSlippage(e.target.value)} />
      </label>
      <p className="muted tiny">Output estimado: ~{estimate > 0n ? (Number(estimate) / 1e18).toFixed(6) : "0"} {outSym}</p>
      {formError && <p className="warn" role="alert">{formError}</p>}
      <div className="actions">
        <button type="button" className="btn btn-primary" disabled={!connected || busy} onClick={submit}>
          {busy ? "Procesando…" : "Swap"}
        </button>
      </div>
    </section>
  );
}
