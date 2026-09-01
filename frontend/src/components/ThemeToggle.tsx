"use client";

import { useTheme, type ThemeMode } from "@/hooks/useTheme";

type ThemeToggleProps = {
  theme?: ThemeMode;
  onToggle?: () => void;
};

/**
 * Botón para alternar modo claro / oscuro.
 */
export function ThemeToggle({ theme: themeProp, onToggle }: ThemeToggleProps = {}) {
  const hook = useTheme();
  const theme = themeProp ?? hook.theme;
  const toggle = onToggle ?? hook.toggleTheme;
  const isDark = theme === "dark";

  return (
    <button
      type="button"
      className="btn btn-ghost theme-toggle"
      data-testid="theme-toggle"
      aria-label={isDark ? "Cambiar a modo claro" : "Cambiar a modo oscuro"}
      title={isDark ? "Modo claro" : "Modo oscuro"}
      onClick={toggle}
    >
      <span aria-hidden="true">{isDark ? "☀" : "☾"}</span>
      <span className="theme-toggle-label">{isDark ? "Claro" : "Oscuro"}</span>
    </button>
  );
}
