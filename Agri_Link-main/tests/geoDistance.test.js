const { haversineKm, isWithinRadius } = require('../src/utils/geoDistance');

describe('Haversine Distance', () => {
  test('distance between same point is 0', () => {
    expect(haversineKm(13.0827, 80.2707, 13.0827, 80.2707)).toBeCloseTo(0, 1);
  });

  test('Chennai to Bangalore is ~290 km', () => {
    const dist = haversineKm(13.0827, 80.2707, 12.9716, 77.5946);
    expect(dist).toBeGreaterThan(280);
    expect(dist).toBeLessThan(310);
  });

  test('isWithinRadius returns true for nearby seller', () => {
    // Same coords → 0 km, within any radius
    expect(isWithinRadius(13.0, 80.0, 13.0, 80.0, 30)).toBe(true);
  });

  test('isWithinRadius returns false for far seller', () => {
    // Chennai to Mumbai ~1300 km, radius 30
    expect(isWithinRadius(13.0827, 80.2707, 19.0760, 72.8777, 30)).toBe(false);
  });
});
