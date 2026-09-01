import { describe, expect, it, vi, afterEach } from "vitest";
import { cleanup, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ThemeToggle } from "@/components/ThemeToggle";
import { TokenSwapApp } from "@/components/TokenSwapApp";

vi.mock("@/lib/env", () => ({
  safeParsePublicEnv: () => ({
    success: false,
    error: { message: "Missing NEXT_PUBLIC_*" },
  }),
}));

afterEach(() => cleanup());

describe("ThemeToggle", () => {
  it("alterna el aria-label entre claro y oscuro", async () => {
    const user = userEvent.setup();
    const onToggle = vi.fn();
    const { rerender } = render(<ThemeToggle theme="dark" onToggle={onToggle} />);
    await user.click(screen.getByRole("button", { name: /cambiar a modo claro/i }));
    expect(onToggle).toHaveBeenCalledOnce();
    rerender(<ThemeToggle theme="light" onToggle={onToggle} />);
    expect(screen.getByRole("button", { name: /cambiar a modo oscuro/i })).toBeInTheDocument();
  });
});

describe("TokenSwapApp", () => {
  it("muestra alerta si falta configuración de env", () => {
    render(<TokenSwapApp />);
    expect(screen.getByRole("alert")).toHaveTextContent(/falta configuración/i);
    expect(screen.getByTestId("theme-toggle")).toBeInTheDocument();
  });
});
