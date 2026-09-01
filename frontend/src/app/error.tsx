"use client";

import { useEffect } from "react";

/**
 * Error boundary de la app.
 */
export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="app-grid">
      <section className="panel" role="alert">
        <h2 className="panel-title">Error</h2>
        <pre className="error-box">{error.message}</pre>
        <button type="button" className="btn btn-primary" onClick={reset}>
          Reintentar
        </button>
      </section>
    </div>
  );
}
