import { describe, expect, it } from "vitest";
import { formatContractError } from "./errors";

describe("formatContractError", () => {
  it("decodifica ERC20InsufficientAllowance", () => {
    const data =
      "0xfb8f41b2000000000000000000000000cf7ed3acca5a467e9e704c703e8d87f634fb0fc900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008ac7230489e80000";
    const msg = formatContractError({ data });
    expect(msg).toContain("Aprobación insuficiente");
    expect(msg).toContain("10.0");
  });

  it("sugiere mint cuando el mensaje es unknown custom error", () => {
    const msg = formatContractError({
      shortMessage: "execution reverted (unknown custom error)",
    });
    expect(msg).toContain("Mint demo");
  });
});
