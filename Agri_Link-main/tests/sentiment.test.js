const { analyzeSentiment } = require('../src/utils/sentiment');

describe('Sentiment Analysis Utility', () => {
  test('classifies positive product reviews correctly', () => {
    const res = analyzeSentiment('The tomatoes were fresh, juicy, and arrived super fast! Excellent quality.');
    expect(res.sentiment).toBe('positive');
    expect(res.sentiment_score).toBeGreaterThan(0);
  });

  test('classifies negative product reviews correctly', () => {
    const res = analyzeSentiment('Very disappointed. The vegetables were stale and delivery was super slow.');
    expect(res.sentiment).toBe('negative');
    expect(res.sentiment_score).toBeLessThan(0);
  });

  test('classifies neutral product reviews correctly', () => {
    const res = analyzeSentiment('The rice was okay, nothing special but delivered on time.');
    expect(res.sentiment).toBe('neutral');
    expect(res.sentiment_score).toBe(0);
  });

  test('handles empty or invalid review input gracefully', () => {
    const res = analyzeSentiment('');
    expect(res.sentiment).toBe('neutral');
    expect(res.sentiment_score).toBe(0);
    expect(res.confidence).toBe(1.0);
  });
});
