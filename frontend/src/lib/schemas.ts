import { z } from "zod";

/** Input positivo de token (string decimal). */
const amountSchema = z
  .string()
  .trim()
  .min(1, "Ingresá un monto")
  .refine((v) => !Number.isNaN(Number(v)) && Number(v) > 0, "Monto inválido");

/** Slippage en puntos básicos (0–5000 = 0–50%). */
const slippageBpsSchema = z.coerce
  .number()
  .int()
  .min(0, "Mínimo 0")
  .max(5000, "Máximo 50%");

/** Formulario de swap token A → B. */
export const swapFormSchema = z.object({
  amountIn: amountSchema,
  slippageBps: slippageBpsSchema,
});

/** Formulario de depósito de liquidez. */
export const addLiquidityFormSchema = z.object({
  amountA: amountSchema,
  amountB: amountSchema,
});

/** Formulario de retiro de liquidez (LP). */
export const removeLiquidityFormSchema = z.object({
  lpAmount: amountSchema,
});

export type SwapFormValues = z.infer<typeof swapFormSchema>;
export type AddLiquidityFormValues = z.infer<typeof addLiquidityFormSchema>;
export type RemoveLiquidityFormValues = z.infer<typeof removeLiquidityFormSchema>;
