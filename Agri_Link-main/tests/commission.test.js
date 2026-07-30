// ─────────────────────────────────────────────────────────────
// tests/commission.test.js
// ─────────────────────────────────────────────────────────────
const { calculate, RATE } = require('../src/utils/commission');

describe('Commission Calculator', () => {
  test('calculates 0% buyer and seller fees on ₹500', () => {
    const result = calculate(500);
    expect(result.buyerFee).toBe(0.00);
    expect(result.sellerFee).toBe(0.00);
    expect(result.platformFee).toBe(0.00);
    expect(result.netPayout).toBe(500.00);
    expect(result.buyerTotal).toBe(500.00);
  });

  test('handles zero amount', () => {
    const result = calculate(0);
    expect(result.buyerFee).toBe(0);
    expect(result.platformFee).toBe(0);
    expect(result.netPayout).toBe(0);
  });

  test('rounds to 2 decimal places on fractional amounts', () => {
    const result = calculate(333.33);
    expect(result.buyerFee).toBe(0.00);
    expect(result.sellerFee).toBe(0.00);
  });

  test('rate matches env COMMISSION_RATE or defaults to 0', () => {
    expect(RATE).toBe(0.00);
  });
});
