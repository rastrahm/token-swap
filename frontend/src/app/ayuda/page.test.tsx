import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import AyudaPage from "@/app/ayuda/page";

describe("AyudaPage", () => {
  it("incluye secciones de instalación y uso", () => {
    render(<AyudaPage />);
    expect(screen.getByRole("heading", { name: /manual de la demo amm/i })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: /instalación local/i })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: /hacer un swap/i })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: /liquidez/i })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: /problemas frecuentes/i })).toBeInTheDocument();
    expect(screen.getByTestId("home-link")).toBeInTheDocument();
  });
});
