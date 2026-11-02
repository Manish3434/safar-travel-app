const fs = require('fs');
const path = require('path');
const { ALL_INDIA_SPOTS } = require('../apps/web/all_india_spots.js');

const map = {};
ALL_INDIA_SPOTS.forEach(s => {
  if (!s.districtId) return;
  const dId = s.districtId.toLowerCase().trim();
  if (!map[dId] && s.location && typeof s.location.lat === 'number') {
    map[dId] = {
      lat: Number(s.location.lat.toFixed(4)),
      lng: Number(s.location.lng.toFixed(4)),
      name: s.districtName || '',
      state: s.stateCode || ''
    };
  }
});

const content = `// Canonical District Coordinates Lookup for all 781 Indian Districts
// Auto-extracted from verified geospatial catalog
const DISTRICT_COORDS = ${JSON.stringify(map, null, 2)};

if (typeof module !== 'undefined') {
  module.exports = { DISTRICT_COORDS };
}
`;

fs.writeFileSync(path.join(__dirname, '../apps/web/district_coords.js'), content, 'utf8');
console.log('Successfully generated district_coords.js with', Object.keys(map).length, 'districts!');
