"use client";

import type { PoolSnapshot } from "@/hooks/useAmm";
import { formatTokens } from "@/lib/format";

type PoolStatsProps = {
  snap: PoolSnapshot;
};

/**
 * Reservas y balances del pool.
 */
export function PoolStats({ snap }: PoolStatsProps) {
  return (
    <section className="panel" aria-label="Pool">
      <h2 className="panel-title">Pool</h2>
      <dl className="stats">
        <div>
          <dt>{snap.tokenASymbol} reserva</dt>
          <dd data-testid="reserve-a">{formatTokens(snap.reserveA)}</dd>
        </div>
        <div>
          <dt>{snap.tokenBSymbol} reserva</dt>
          <dd data-testid="reserve-b">{formatTokens(snap.reserveB)}</dd>
        </div>
        <div>
          <dt>Tu {snap.tokenASymbol}</dt>
          <dd>{formatTokens(snap.balanceA)}</dd>
        </div>
        <div>
          <dt>Tu {snap.tokenBSymbol}</dt>
          <dd>{formatTokens(snap.balanceB)}</dd>
        </div>
        <div>
          <dt>LP balance</dt>
          <dd data-testid="lp-balance">{formatTokens(snap.lpBalance)}</dd>
        </div>
        <div>
          <dt>Fee swap</dt>
          <dd>0.30%</dd>
        </div>
      </dl>
    </section>
  );
}
