const { ALL_INDIA_SPOTS } = require('../apps/web/all_india_spots.js');

const districtMap = new Map();
let withValidCoords = 0;
let withoutCoords = 0;

ALL_INDIA_SPOTS.forEach(s => {
  if (!s.districtId) return;
  if (s.location && typeof s.location.lat === 'number' && typeof s.location.lng === 'number') {
    withValidCoords++;
    if (!districtMap.has(s.districtId)) {
      districtMap.set(s.districtId, { lat: s.location.lat, lng: s.location.lng, state: s.stateCode });
    }
  } else {
    withoutCoords++;
  }
});

console.log('Total spots with valid coords:', withValidCoords);
console.log('Total spots without coords:', withoutCoords);
console.log('Unique districts covered:', districtMap.size);

// Check Kohima
console.log('nl-kohima in map:', districtMap.get('nl-kohima'));
// Check Kangra
console.log('hp-kangra in map:', districtMap.get('hp-kangra'));
// Check Leh
console.log('la-leh in map:', districtMap.get('la-leh'));
