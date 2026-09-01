"use client";

import Link from "next/link";
import { ThemeToggle } from "@/components/ThemeToggle";

type AppToolbarProps = {
  showHome?: boolean;
};

/**
 * Barra superior: ayuda + tema.
 */
export function AppToolbar({ showHome = false }: AppToolbarProps) {
  return (
    <div className="hero-top toolbar">
      {showHome ? (
        <Link href="/" className="btn btn-ghost" data-testid="home-link">
          ← Swap
        </Link>
      ) : (
        <Link href="/ayuda" className="btn btn-ghost" data-testid="help-link" aria-label="Ayuda">
          ? Ayuda
        </Link>
      )}
      <ThemeToggle />
    </div>
  );
}
