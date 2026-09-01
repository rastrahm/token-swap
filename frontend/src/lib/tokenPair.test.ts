import { describe, expect, it } from "vitest";
import { tokenPairSchema } from "./tokenPair";

describe("tokenPairSchema", () => {
  const a = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const b = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

  it("acepta dos addresses distintas", () => {
    expect(tokenPairSchema.safeParse({ tokenA: a, tokenB: b }).success).toBe(true);
  });

  it("rechaza addresses iguales", () => {
    expect(tokenPairSchema.safeParse({ tokenA: a, tokenB: a }).success).toBe(false);
  });

  it("rechaza hex inválido", () => {
    expect(tokenPairSchema.safeParse({ tokenA: "0x123", tokenB: b }).success).toBe(false);
  });
});
