import Link from "next/link";

/**
 * Página 404.
 */
export default function NotFound() {
  return (
    <div className="app-grid">
      <section className="panel">
        <h1 className="panel-title">No encontrado</h1>
        <p className="muted">La ruta no existe.</p>
        <Link href="/" className="btn btn-primary">Volver al swap</Link>
      </section>
    </div>
  );
}
