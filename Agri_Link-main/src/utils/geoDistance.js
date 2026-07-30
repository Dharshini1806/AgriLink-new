const EARTH_RADIUS_KM = 6371;

/**
 * Haversine distance between two GPS coordinates
 * @param {number} lat1
 * @param {number} lon1
 * @param {number} lat2
 * @param {number} lon2
 * @returns {number} distance in km
 */
function haversineKm(lat1, lon1, lat2, lon2) {
  const toRad = deg => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Check if a buyer is within a seller's delivery radius
 */
function isWithinRadius(buyerLat, buyerLng, sellerLat, sellerLng, radiusKm) {
  return haversineKm(buyerLat, buyerLng, sellerLat, sellerLng) <= radiusKm;
}

module.exports = { haversineKm, isWithinRadius };
