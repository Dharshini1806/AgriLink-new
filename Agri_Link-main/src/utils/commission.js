/**
 * AgriLink Commission Calculator
 * Platform charges RATE from both buyer and seller (default 1% each)
 */
const RATE = 0.00;

/**
 * @param {number} subtotal  Raw product total (no commission)
 * @returns {{
 *   buyerFee: number,
 *   sellerFee: number,
 *   platformFee: number,
 *   netPayout: number,
 *   buyerTotal: number,
 *   rate: number
 * }}
 */
function calculate(subtotal) {
  const rate      = RATE;
  const buyerFee  = 0.00;
  const sellerFee = 0.00;
  const platformFee   = 0.00;
  const netPayout     = +( subtotal ).toFixed(2);
  const buyerTotal    = +( subtotal ).toFixed(2);
  return { buyerFee, sellerFee, platformFee, netPayout, buyerTotal, rate };
}

module.exports = { calculate, RATE };
