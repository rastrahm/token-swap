"use client";

import { useMemo } from "react";
import { AppToolbar } from "@/components/AppToolbar";
import { LiquidityPanel } from "@/components/LiquidityPanel";
import { PoolStats } from "@/components/PoolStats";
import { SwapPanel } from "@/components/SwapPanel";
import { TokenConfigPanel } from "@/components/TokenConfigPanel";
import { useAmm } from "@/hooks/useAmm";
import { useTokenPair } from "@/hooks/useTokenPair";
import { useWallet } from "@/hooks/useWallet";
import { safeParsePublicEnv, type PublicEnv } from "@/lib/env";
import { shortAddress } from "@/lib/format";

/**
 * Demo UI: wallet, swap y liquidez sobre Anvil.
 */
export function TokenSwapApp() {
  const envResult = useMemo(() => safeParsePublicEnv(), []);
  const env: PublicEnv | null = envResult.success ? envResult.data : null;
  const wallet = useWallet(env);
  const tokenPair = useTokenPair(env);
  const amm = useAmm(env, tokenPair.config, wallet.address, wallet.signer);

  if (!envResult.success || !env) {
    return (
      <div className="app-grid">
        <AppToolbar />
        <section className="panel" role="alert">
          <h2 className="panel-title">Falta configuración</h2>
          <p className="muted">
            Copiá <code>.env.example</code> → <code>.env.local</code> con las addresses del deploy.
            Ver <a href="/ayuda">/ayuda</a>.
          </p>
          <pre className="error-box">
            {envResult.success ? "Env incompleto" : envResult.error.message}
          </pre>
        </section>
      </div>
    );
  }

  const ready = !!tokenPair.config?.pair;

  return (
    <div className="app-grid">
      <header className="hero">
        <AppToolbar />
        <p className="brand">Token Swap</p>
        <h1 className="headline">Constant Product AMM</h1>
        <p className="lede">Swap y liquidez con fee 0.3% · producto constante x·y=k</p>
        <div className="cta-row">
          {!wallet.address ? (
            <button type="button" className="btn btn-primary" onClick={() => void wallet.connect()} disabled={wallet.connecting}>
              {wallet.connecting ? "Conectando…" : "Conectar wallet"}
            </button>
          ) : (
            <>
              <span className="pill" data-testid="wallet-address">{shortAddress(wallet.address)}</span>
              <button type="button" className="btn btn-ghost" onClick={wallet.disconnect}>Desconectar</button>
            </>
          )}
        </div>
        {(wallet.error || wallet.wrongChain) && (
          <p className="warn" role="status">
            {wallet.wrongChain ? `Red incorrecta (esperada ${env.NEXT_PUBLIC_CHAIN_ID})` : wallet.error}
          </p>
        )}
        {amm.status && <p className="muted tiny" role="status">{amm.status}</p>}
        {amm.error && <pre className="error-box" role="alert">{amm.error}</pre>}
      </header>

      <TokenConfigPanel
        draftA={tokenPair.draftA}
        draftB={tokenPair.draftB}
        pairAddress={tokenPair.config?.pair ?? null}
        symbolA={ready ? amm.snap.tokenASymbol : undefined}
        symbolB={ready ? amm.snap.tokenBSymbol : undefined}
        busy={tokenPair.busy}
        error={tokenPair.error}
        onDraftAChange={tokenPair.setDraftA}
        onDraftBChange={tokenPair.setDraftB}
        onApply={tokenPair.applyDraft}
        onSwap={tokenPair.swapTokens}
        onReset={tokenPair.resetToDeploy}
      />

      {ready && (
        <>
          <PoolStats snap={amm.snap} />
          <SwapPanel
            snap={amm.snap}
            busy={amm.busy}
            connected={!!wallet.address}
            onSwapAforB={(a, s) => void amm.swapAforB(a, s)}
            onSwapBforA={(a, s) => void amm.swapBforA(a, s)}
          />
          <LiquidityPanel
            snap={amm.snap}
            busy={amm.busy}
            connected={!!wallet.address}
            onAdd={(a, b) => void amm.addLiquidity(a, b)}
            onRemove={(lp) => void amm.removeLiquidity(lp)}
            onMintDemo={() => void amm.mintDemoTokens()}
          />
        </>
      )}
    </div>
  );
}
