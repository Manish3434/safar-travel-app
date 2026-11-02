/**
 * Verification script for In-App Split Map, Multi-Modal Modes (Cycle, Bike, Car, etc.),
 * Toll Gate Calculator, and Avoid Tolls Bypass Route.
 */
const fs = require('fs');
const path = require('path');
const vm = require('vm');

console.log('--- 1. Testing HTML Split Map Structure ---');
const html = fs.readFileSync(path.join(__dirname, '../apps/web/index.html'), 'utf8');

const requiredElements = [
  'mapSplitContainer',
  'mapRoutePanelLeft',
  'mapScreenView',
  'fullExplorerMap',
  'mapTransportModesGrid',
  'data-mode="cycle"',
  'data-mode="car"',
  'data-mode="bike"',
  'data-mode="flight"',
  'data-mode="train"',
  'avoidTollsSwitch',
  'cardFastestRoute',
  'cardTollFreeRoute',
  'mapTollCountPill',
  'mapTollFeeVal',
  'mapTollPlazasList',
  'avoidInstructionsBox'
];

requiredElements.forEach(elem => {
  if (html.includes(elem)) {
    console.log(`✅ Element found in index.html: ${elem}`);
  } else {
    console.error(`❌ Missing element in index.html: ${elem}`);
    process.exit(1);
  }
});

console.log('\n--- 2. Testing API_SERVICE.calculateRoute Logic ---');
// Set up sandbox environment
const sandbox = {
  window: {
    addEventListener: () => {},
    removeEventListener: () => {}
  },
  document: {
    getElementById: () => null,
    querySelectorAll: () => [],
    addEventListener: () => {},
    removeEventListener: () => {}
  },
  navigator: {},
  localStorage: { getItem: () => null, setItem: () => {} },
  fetch: () => Promise.resolve({ ok: false }),
  console: console,
  setTimeout: setTimeout,
  clearTimeout: clearTimeout,
  addEventListener: () => {},
  removeEventListener: () => {}
};
sandbox.window.window = sandbox.window;
sandbox.window.document = sandbox.document;

const appJs = fs.readFileSync(path.join(__dirname, '../apps/web/app.js'), 'utf8');
vm.createContext(sandbox);
vm.runInContext(appJs, sandbox);

async function runRouteTests() {
  const origin = 'Coimbatore, Tamil Nadu';
  const dest = 'Ooty Botanical Gardens, Tamil Nadu';
  const originCoords = { lat: 11.0168, lng: 76.9558 };
  const destCoords = { lat: 11.4168, lng: 76.7118 };

  const route = await sandbox.window.API_SERVICE.calculateRoute(origin, dest, originCoords, destCoords);

  console.log(`Route distance: ${route.distanceKm} km`);
  console.log(`Cycle duration: ${route.modes.cycle.duration}`);
  console.log(`Car duration: ${route.modes.car.duration}`);
  console.log(`Car toll count: ${route.modes.car.tollCount}, fee: ₹${route.modes.car.tollFeeInr}`);
  console.log(`Bike toll count: ${route.modes.bike.tollCount}, fee: ₹${route.modes.bike.tollFeeInr}`);
  console.log(`Avoid tolls distance: ${route.avoidTolls.distanceKm} km, fee: ₹${route.avoidTolls.tollFeeInr}`);

  if (!route.modes.cycle || !route.modes.cycle.duration) {
    throw new Error('Cycle mode missing duration');
  }
  if (route.modes.bike.tollCount !== 0) {
    throw new Error('Two-wheelers should be toll exempt');
  }
  if (!route.avoidTolls || route.avoidTolls.tollCount !== 0) {
    throw new Error('Avoid tolls route should have 0 tolls');
  }
  if (!Array.isArray(route.avoidTolls.instructions) || route.avoidTolls.instructions.length === 0) {
    throw new Error('Avoid tolls should have detour bypass instructions');
  }

  console.log('\n--- 3. Testing Long-Distance Route with Toll Plazas ---');
  // Long distance: Bengaluru to Chennai (~350 km)
  const blrCoords = { lat: 12.9716, lng: 77.5946 };
  const maaCoords = { lat: 13.0827, lng: 80.2707 };
  const longRoute = await sandbox.window.API_SERVICE.calculateRoute('Bengaluru', 'Chennai', blrCoords, maaCoords);

  console.log(`BLR -> MAA distance: ${longRoute.distanceKm} km`);
  console.log(`Toll count: ${longRoute.tolls.count} plazas, Total fee: ₹${longRoute.tolls.totalFeeInr}`);
  console.log(`Toll plazas generated: ${longRoute.tolls.plazas.length}`);
  console.log(`Toll-free savings: ₹${longRoute.avoidTolls.savedInr}`);

  if (longRoute.tolls.count < 3) {
    throw new Error(`Expected at least 3 tolls for ~350 km route, got ${longRoute.tolls.count}`);
  }
  if (longRoute.tolls.plazas.length !== longRoute.tolls.count) {
    throw new Error('Toll plazas array length mismatch');
  }
  if (longRoute.avoidTolls.savedInr !== longRoute.tolls.totalFeeInr) {
    throw new Error('Avoid tolls savings should equal highway toll fee');
  }

  console.log('\n🎉 ALL SPLIT MAP, MODAL MODES, AND TOLL CALCULATOR TESTS PASSED!');
}

runRouteTests().catch(err => {
  console.error('Test Failed:', err);
  process.exit(1);
});
