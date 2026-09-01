"use client";

import { useState } from "react";
import type { PoolSnapshot } from "@/hooks/useAmm";
import { addLiquidityFormSchema, removeLiquidityFormSchema } from "@/lib/schemas";

type LiquidityPanelProps = {
  snap: PoolSnapshot;
  busy: boolean;
  connected: boolean;
  onAdd: (amountA: string, amountB: string) => void;
  onRemove: (lpAmount: string) => void;
  onMintDemo: () => void;
};

/**
 * Panel de liquidez: add / remove + mint demo.
 */
export function LiquidityPanel({ snap, busy, connected, onAdd, onRemove, onMintDemo }: LiquidityPanelProps) {
  const [mode, setMode] = useState<"add" | "remove">("add");
  const [amountA, setAmountA] = useState("10");
  const [amountB, setAmountB] = useState("10");
  const [lpAmount, setLpAmount] = useState("1");
  const [formError, setFormError] = useState<string | null>(null);

  const submit = () => {
    if (mode === "add") {
      const parsed = addLiquidityFormSchema.safeParse({ amountA, amountB });
      if (!parsed.success) {
        setFormError(parsed.error.issues[0]?.message ?? "Datos inválidos");
        return;
      }
      setFormError(null);
      onAdd(parsed.data.amountA, parsed.data.amountB);
      return;
    }
    const parsed = removeLiquidityFormSchema.safeParse({ lpAmount });
    if (!parsed.success) {
      setFormError(parsed.error.issues[0]?.message ?? "Datos inválidos");
      return;
    }
    setFormError(null);
    onRemove(parsed.data.lpAmount);
  };

  return (
    <section className="panel" aria-label="Liquidez">
      <h2 className="panel-title">Liquidez</h2>
      <div className="actions tab-row">
        <button type="button" className={`btn ${mode === "add" ? "btn-primary" : "btn-ghost"}`} onClick={() => setMode("add")}>Depositar</button>
        <button type="button" className={`btn ${mode === "remove" ? "btn-primary" : "btn-ghost"}`} onClick={() => setMode("remove")}>Retirar</button>
      </div>
      {mode === "add" ? (
        <>
          <label className="field">{snap.tokenASymbol}<input aria-label="Cantidad A" value={amountA} onChange={(e) => setAmountA(e.target.value)} /></label>
          <label className="field">{snap.tokenBSymbol}<input aria-label="Cantidad B" value={amountB} onChange={(e) => setAmountB(e.target.value)} /></label>
        </>
      ) : (
        <label className="field">LP a quemar<input aria-label="Cantidad LP" value={lpAmount} onChange={(e) => setLpAmount(e.target.value)} /></label>
      )}
      {formError && <p className="warn" role="alert">{formError}</p>}
      {mode === "add" && connected && (
        <p className="muted tiny">
          Primero «Mint demo 10k». Al depositar, MetaMask pedirá hasta 2 aprobaciones (approve) y luego la tx de liquidez.
        </p>
      )}
      <div className="actions">
        <button type="button" className="btn btn-primary" disabled={!connected || busy} onClick={submit}>
          {busy ? "Procesando…" : mode === "add" ? "Añadir liquidez" : "Retirar liquidez"}
        </button>
        <button type="button" className="btn btn-ghost" disabled={!connected || busy} onClick={onMintDemo}>Mint demo 10k</button>
      </div>
    </section>
  );
}
