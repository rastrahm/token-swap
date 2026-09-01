"use client";

import { shortAddress } from "@/lib/format";

type TokenConfigPanelProps = {
  draftA: string;
  draftB: string;
  pairAddress: string | null;
  symbolA?: string;
  symbolB?: string;
  busy: boolean;
  error: string | null;
  onDraftAChange: (v: string) => void;
  onDraftBChange: (v: string) => void;
  onApply: () => void;
  onSwap: () => void;
  onReset: () => void;
};

/**
 * Configuración de tokens ALPHA / BETA (addresses + invertir).
 */
export function TokenConfigPanel({
  draftA,
  draftB,
  pairAddress,
  symbolA,
  symbolB,
  busy,
  error,
  onDraftAChange,
  onDraftBChange,
  onApply,
  onSwap,
  onReset,
}: TokenConfigPanelProps) {
  return (
    <section className="panel" aria-label="Tokens del par">
      <h2 className="panel-title">Par de tokens</h2>
      <p className="muted tiny">Cambiá las addresses ALPHA/BETA. El par se resuelve en la factory.</p>
      <label className="field">
        ALPHA {symbolA ? `(${symbolA})` : ""}
        <input
          aria-label="Address token ALPHA"
          value={draftA}
          onChange={(e) => onDraftAChange(e.target.value)}
          placeholder="0x…"
          spellCheck={false}
        />
      </label>
      <label className="field">
        BETA {symbolB ? `(${symbolB})` : ""}
        <input
          aria-label="Address token BETA"
          value={draftB}
          onChange={(e) => onDraftBChange(e.target.value)}
          placeholder="0x…"
          spellCheck={false}
        />
      </label>
      {pairAddress && (
        <p className="muted tiny" data-testid="pair-address">
          Par activo: <code>{shortAddress(pairAddress)}</code>
        </p>
      )}
      {error && <p className="warn" role="alert">{error}</p>}
      <div className="actions">
        <button type="button" className="btn btn-primary" disabled={busy} onClick={onApply}>
          {busy ? "Validando…" : "Aplicar"}
        </button>
        <button type="button" className="btn btn-ghost" disabled={busy} onClick={onSwap} aria-label="Intercambiar ALPHA y BETA">
          ⇄ Invertir A/B
        </button>
        <button type="button" className="btn btn-ghost" disabled={busy} onClick={onReset}>
          Restaurar deploy
        </button>
      </div>
    </section>
  );
}
