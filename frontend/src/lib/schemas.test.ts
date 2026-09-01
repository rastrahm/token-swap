import { describe, expect, it } from "vitest";
import { swapFormSchema } from "./schemas";

describe("swapFormSchema", () => {
  it("acepta monto y slippage válidos", () => {
    const r = swapFormSchema.safeParse({ amountIn: "1.5", slippageBps: 50 });
    expect(r.success).toBe(true);
  });

  it("rechaza monto cero", () => {
    const r = swapFormSchema.safeParse({ amountIn: "0", slippageBps: 50 });
    expect(r.success).toBe(false);
  });

  it("rechaza slippage excesivo", () => {
    const r = swapFormSchema.safeParse({ amountIn: "1", slippageBps: 6000 });
    expect(r.success).toBe(false);
  });
});
