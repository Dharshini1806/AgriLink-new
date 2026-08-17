const Sentiment = require('sentiment');
const sentiment = new Sentiment();

/**
 * Pre-processes review text to catch key multi-word phrases and negations
 * @param {string} text 
 * @returns {string} processed text
 */
function preprocessText(text) {
  let processed = text.toLowerCase();

  // Convert key multi-word negative phrases into single alphanumeric tokens
  processed = processed
    .replace(/\bnever\s+buy(ing)?\b/g, 'neverbuy')
    .replace(/\bnot\s+fast\b/g, 'notfast')
    .replace(/\bnot\s+fresh\b/g, 'notfresh')
    .replace(/\bnot\s+good\b/g, 'notgood')
    .replace(/\bnot\s+worth\b/g, 'notworth')
    .replace(/\bdon'?t\s+buy\b/g, 'dontbuy')
    .replace(/\bwaste\s+of\s+(money|time)\b/g, 'wasteofmoney')
    .replace(/\bpoor\s+quality\b/g, 'poorquality')
    .replace(/\bbad\s+quality\b/g, 'badquality');

  return processed;
}

/**
 * Analyze sentiment of review comment/text
 * @param {string} text review comment
 * @param {number} [rating] optional star rating (1 to 5)
 * @returns {object} Sentiment classification analysis results
 */
function analyzeSentiment(text, rating = null) {
  if (!text || typeof text !== 'string' || !text.trim()) {
    let defaultLabel = 'neutral';
    let defaultScore = 0.0;
    if (typeof rating === 'number') {
      if (rating >= 4) { defaultLabel = 'positive'; defaultScore = 2.0; }
      else if (rating <= 2) { defaultLabel = 'negative'; defaultScore = -2.0; }
    }
    return {
      sentiment: defaultLabel,
      sentiment_score: defaultScore,
      sentiment_label: defaultLabel,
      confidence: 1.0,
    };
  }

  const processedText = preprocessText(text);

  const options = {
    extras: {
      // 🟢 Positive Produce & Quality Words
      fresh: 3,
      juicy: 2,
      organic: 2,
      delicious: 3,
      tasty: 3,
      sweet: 2,
      crisp: 2,
      ripe: 2,
      pure: 3,
      authentic: 3,
      hygienic: 3,
      clean: 2,
      unadulterated: 4,
      excellent: 4,
      amazing: 4,
      best: 3,
      satisfied: 3,
      great: 3,
      good: 2,
      fast: 2,
      prompt: 3,
      helpful: 2,
      polite: 2,

      // 🔴 Negative Produce & Quality Words
      stale: -3,
      rotten: -4,
      spoiled: -4,
      damaged: -3,
      overpriced: -3,
      expensive: -2,
      bruised: -2,
      smelly: -3,
      stink: -3,
      stinky: -3,
      rancid: -4,
      foul: -3,
      mold: -4,
      moldy: -4,
      fungus: -4,
      fungal: -4,
      worm: -4,
      worms: -4,
      insect: -3,
      insects: -3,
      bugs: -3,
      maggot: -5,
      maggots: -5,
      pest: -3,
      pests: -3,
      adulterated: -4,
      adulteration: -4,
      fake: -3,
      fraud: -4,
      scam: -4,
      cheated: -4,
      unusable: -4,
      dirty: -3,
      toxic: -5,
      poisonous: -5,
      disappointed: -3,
      disappointing: -3,
      terrible: -4,
      worst: -4,
      slow: -2,
      delayed: -2,
      delay: -2,
      poor: -3,

      // 🛑 Multi-word alphanumeric phrase tokens
      neverbuy: -4,
      notfast: -2,
      notfresh: -3,
      notgood: -3,
      notworth: -4,
      dontbuy: -4,
      wasteofmoney: -4,
      poorquality: -4,
      badquality: -4,

      // Modifiers
      super: 1,
    }
  };

  const result = sentiment.analyze(processedText, options);
  let totalScore = result.score;

  // Incorporate numerical rating context if provided
  if (typeof rating === 'number' && !isNaN(rating)) {
    if (rating === 1) totalScore -= 3;
    else if (rating === 2) totalScore -= 1.5;
    else if (rating === 5) totalScore += 2;
  }

  let label = 'neutral';
  if (totalScore > 0) {
    label = 'positive';
  } else if (totalScore < 0) {
    label = 'negative';
  }

  // Calculate sentiment confidence based on comparative score
  const comparativeAbs = Math.abs(result.comparative || 0);
  const confidence = totalScore === 0 ? 1.0 : Math.min(1.0, Math.max(0.2, comparativeAbs / 1.5));

  return {
    sentiment: label,
    sentiment_score: parseFloat(totalScore.toFixed(2)),
    sentiment_label: label,
    confidence: parseFloat(confidence.toFixed(2)),
  };
}

module.exports = { analyzeSentiment };
