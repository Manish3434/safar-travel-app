const fs = require('fs');
const path = require('path');
const vm = require('vm');

console.log('--- Verifying Spot & District Geographic Coordinates Accuracy ---');

// Set up browser-like DOM mocks for Node VM
const windowMock = {
  location: { hash: '', pathname: '/', search: '', replaceState: () => {}, pushState: () => {} },
  history: { state: null, replaceState: () => {}, pushState: () => {} },
  addEventListener: () => {},
  removeEventListener: () => {},
  localStorage: { getItem: () => null, setItem: () => {} },
  USER_LIVE_LOCATION: { lat: 11.0168, lng: 76.9558, name: 'Coimbatore, Tamil Nadu' },
  innerWidth: 1440,
  innerHeight: 900
};

const domElements = new Map();
const getMockEl = (id) => {
  if (!domElements.has(id)) {
    domElements.set(id, {
      id,
      style: {},
      classList: {
        contains: () => false,
        add: () => {},
        remove: () => {},
        toggle: () => {}
      },
      textContent: '',
      innerHTML: '',
      setAttribute: () => {},
      getAttribute: () => null,
      querySelector: () => ({ setAttribute: () => {} }),
      querySelectorAll: () => []
    });
  }
  return domElements.get(id);
};

const documentMock = {
  getElementById: (id) => getMockEl(id),
  querySelector: () => null,
  querySelectorAll: () => [],
  createElement: (tag) => getMockEl(tag),
  body: { style: {} },
  documentElement: { scrollHeight: 2000, clientHeight: 900 },
  addEventListener: () => {}
};

const sandbox = {
  window: windowMock,
  document: documentMock,
  localStorage: windowMock.localStorage,
  navigator: { language: 'en', userAgent: 'Node' },
  console,
  setTimeout: (fn) => setTimeout(fn, 0),
  clearTimeout,
  requestAnimationFrame: (fn) => fn(),
  L: {
    map: () => ({
      setView: () => {},
      invalidateSize: () => {},
      eachLayer: () => {},
      on: () => {},
      fitBounds: () => {}
    }),
    tileLayer: () => ({ addTo: () => {} }),
    marker: () => ({ addTo: () => ({ bindPopup: () => ({ openPopup: () => {} }) }), bindPopup: () => ({ openPopup: () => {} }) }),
    polyline: () => ({ addTo: () => {} }),
    divIcon: () => ({}),
    latLngBounds: () => ({})
  }
};

vm.createContext(sandbox);

// 1. Load district coords, spots, and app scripts in correct order
const files = [
  'apps/web/district_coords.js',
  'apps/web/kerala_spots.js',
  'apps/web/tamilnadu_spots.js',
  'apps/web/all_india_beaches.js',
  'apps/web/all_india_spots.js',
  'apps/web/districts.js',
  'apps/web/data.js',
  'apps/web/app.js'
];

files.forEach(f => {
  const code = fs.readFileSync(path.join(__dirname, '..', f), 'utf8');
  vm.runInContext(code, sandbox);
});

console.log('✅ All data catalogs and application scripts loaded successfully in VM!\n');

// 2. Test Kohima, Nagaland spots
async function runTests() {
  console.log('--- 1. Testing Kohima, Nagaland Coordinates ---');
  const api = sandbox.window.API_SERVICE || sandbox.API_SERVICE;
  const kohimaSpots = await api.getPlacesByDistrict('nl-kohima');
  console.log('Kohima spots returned:', kohimaSpots.length);
  if (kohimaSpots.length === 0) throw new Error('No spots returned for Kohima!');

  const spot1 = kohimaSpots[0];
  console.log('First Kohima spot:', spot1.name);
  console.log('Location:', spot1.location);
  console.log('State:', spot1.stateCode, spot1.stateName);

  // Must be in Nagaland (~25°N, ~93°-94°E), NOT Tamil Nadu (~11°N, ~77°E)
  if (spot1.location.lat < 24.0 || spot1.location.lat > 27.5 || spot1.location.lng < 92.0 || spot1.location.lng > 96.0) {
    throw new Error(`Kohima spot has wrong coordinates: ${JSON.stringify(spot1.location)}! Expected Nagaland (~25°N, ~94°E)`);
  }
  console.log('✅ Kohima spots have accurate Nagaland coordinates!\n');

  console.log('--- 2. Testing Kangra, Himachal Pradesh Coordinates ---');
  const kangraSpots = await api.getPlacesByDistrict('hp-kangra');
  console.log('Kangra spots returned:', kangraSpots.length);
  const hpSpot = kangraSpots[0];
  console.log('First Kangra spot:', hpSpot.name);
  console.log('Location:', hpSpot.location);

  // Must be in Himachal Pradesh (~31°-32°N, ~76°-77°E)
  if (hpSpot.location.lat < 30.0 || hpSpot.location.lat > 33.5 || hpSpot.location.lng < 75.0 || hpSpot.location.lng > 79.0) {
    throw new Error(`Kangra spot has wrong coordinates: ${JSON.stringify(hpSpot.location)}! Expected HP (~31.5°N, ~76.5°E)`);
  }
  console.log('✅ Kangra spots have accurate Himachal Pradesh coordinates!\n');

  console.log('--- 3. Testing Coordinate Auto-Correction on Modal Open ---');
  // Pass a spot with dummy Tamil Nadu coords for Nagaland
  const dummyNagalandSpot = {
    id: 'spot-nl-kohima-curated-4',
    name: 'Kohima Eco Rainforest & Biodiversity Valley',
    stateCode: 'NL',
    stateName: 'Nagaland',
    districtId: 'nl-kohima',
    districtName: 'Kohima',
    location: { lat: 11.1500, lng: 77.1500 } // previously wrong coords
  };

  sandbox.openSpotDetailsModal(dummyNagalandSpot);
  console.log('After modal open, activeSpot location:', sandbox.activeSpot.location);

  if (sandbox.activeSpot.location.lat < 24.0 || sandbox.activeSpot.location.lng < 92.0) {
    throw new Error(`Auto-correction failed! activeSpot still has wrong coords: ${JSON.stringify(sandbox.activeSpot.location)}`);
  }
  console.log('✅ Misplaced Nagaland spot coordinates were automatically corrected to Kohima, Nagaland!\n');

  console.log('🎉 ALL GEOGRAPHIC LOCATION ACCURACY TESTS PASSED!');
}

runTests().catch(err => {
  console.error('❌ Test failed:', err);
  process.exit(1);
});
