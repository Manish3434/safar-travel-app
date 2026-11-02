const fs = require('fs');
const path = require('path');
const vm = require('vm');

console.log('--- Testing openSpotDetailsModal with Various Spot Types ---');

// Mock DOM
const elementMap = {};
function getMockElement(id) {
  if (!elementMap[id]) {
    elementMap[id] = {
      id,
      textContent: '',
      innerHTML: '',
      src: '',
      style: {},
      classList: {
        _classes: new Set(),
        add(c) { this._classes.add(c); },
        remove(c) { this._classes.delete(c); },
        toggle(c, force) {
          if (force !== undefined) {
            if (force) this._classes.add(c); else this._classes.delete(c);
          } else {
            if (this._classes.has(c)) this._classes.delete(c); else this._classes.add(c);
          }
        },
        contains(c) { return this._classes.has(c); }
      },
      appendChild: () => {},
      removeChild: () => {},
      remove: () => {},
      querySelector: () => ({ setAttribute: () => {} })
    };
  }
  return elementMap[id];
}

const sandbox = {
  window: {
    addEventListener: () => {},
    removeEventListener: () => {},
    USER_LIVE_LOCATION: { lat: 11.3410, lng: 77.7172, name: 'Erode, Tamil Nadu', cityName: 'Erode' }
  },
  document: {
    getElementById: (id) => getMockElement(id),
    createElement: (tag) => getMockElement(tag + '_' + Math.random()),
    querySelectorAll: () => [],
    addEventListener: () => {},
    removeEventListener: () => {},
    body: { style: {}, appendChild: () => {} }
  },
  navigator: {},
  localStorage: { getItem: () => null, setItem: () => {} },
  console: console,
  setTimeout: (fn) => fn(),
  clearTimeout: () => {},
  AbortController: AbortController,
  addEventListener: () => {},
  removeEventListener: () => {}
};
sandbox.window.window = sandbox.window;
sandbox.window.document = sandbox.document;

// Load data files
const dataJs = fs.readFileSync(path.join(__dirname, '../apps/web/data.js'), 'utf8');
const tnSpotsJs = fs.readFileSync(path.join(__dirname, '../apps/web/tamilnadu_spots.js'), 'utf8');
const appJs = fs.readFileSync(path.join(__dirname, '../apps/web/app.js'), 'utf8');

vm.createContext(sandbox);
vm.runInContext(dataJs, sandbox);
vm.runInContext(tnSpotsJs, sandbox);
vm.runInContext(appJs, sandbox);

console.log('App scripts loaded in VM successfully!');

// Test 1: Open an ATTRACTIONS_DATA spot ("spot-001" / Marina Beach)
console.log('\n--- 1. Testing ATTRACTIONS_DATA spot ("spot-001" / Marina Beach) ---');
sandbox.window.openSpotDetailsModal('spot-001');
let modal = getMockElement('spotDetailsModal');
let title = getMockElement('spotDetailTitle');
console.log('Title displayed:', title.textContent);
console.log('Modal has "open" class:', modal.classList.contains('open'));
if (!modal.classList.contains('open') || !title.textContent) {
  throw new Error('Failed to open ATTRACTIONS_DATA spot');
}
console.log('✅ ATTRACTIONS_DATA spot opened successfully!');

// Test 2: Open a TAMILNADU_SPOTS spot (which was previously broken!)
console.log('\n--- 2. Testing TAMILNADU_SPOTS spot ("spot-tn-ero-01" / Sangameshwarar Temple) ---');
modal.classList.remove('open');
sandbox.window.openSpotDetailsModal('spot-tn-ero-01');
console.log('Title displayed:', title.textContent);
console.log('Modal has "open" class:', modal.classList.contains('open'));
if (!modal.classList.contains('open') || !title.textContent.includes('Sangameswarar')) {
  throw new Error('Failed to open TAMILNADU_SPOTS spot "spot-tn-ero-01"');
}
console.log('✅ TAMILNADU_SPOTS spot opened successfully!');

// Test 3: Open Bhavanisagar Dam ("spot-tn-ero-02")
console.log('\n--- 3. Testing Bhavanisagar Dam ("spot-tn-ero-02") ---');
modal.classList.remove('open');
sandbox.window.openSpotDetailsModal('spot-tn-ero-02');
console.log('Title displayed:', title.textContent);
console.log('Distance displayed:', getMockElement('spotDetailDistance').textContent);
console.log('Rating displayed:', getMockElement('spotDetailRating').textContent);
console.log('Modal has "open" class:', modal.classList.contains('open'));
if (!modal.classList.contains('open') || !title.textContent.includes('Bhavanisagar')) {
  throw new Error('Failed to open Bhavanisagar Dam');
}
console.log('✅ Bhavanisagar Dam opened successfully!');

// Test 4: Open spot by Object directly
console.log('\n--- 4. Testing Spot passed as Object ---');
modal.classList.remove('open');
const testObj = {
  id: 'custom-lake-99',
  name: 'Vellode Bird Sanctuary Lake',
  category: 'lake',
  categoryLabel: 'Lake & Bird Sanctuary',
  categoryIcon: '🦜',
  districtName: 'Erode',
  stateName: 'Tamil Nadu',
  rating: 4.7,
  location: { lat: 11.25, lng: 77.65 },
  description: 'Tranquil wetland sanctuary and lake hosting migratory avian visitors.'
};
sandbox.window.openSpotDetailsModal(testObj);
console.log('Title displayed:', title.textContent);
console.log('Modal has "open" class:', modal.classList.contains('open'));
if (!modal.classList.contains('open') || !title.textContent.includes('Vellode')) {
  throw new Error('Failed to open spot passed as Object');
}
console.log('✅ Spot passed as object opened successfully!');

// Test 5: Open spot by Name
console.log('\n--- 5. Testing Spot lookup by Name ---');
modal.classList.remove('open');
sandbox.window.openSpotDetailsModal('Bhavanisagar Dam & Earth Dam');
console.log('Title displayed:', title.textContent);
console.log('Modal has "open" class:', modal.classList.contains('open'));
if (!modal.classList.contains('open') || !title.textContent.includes('Bhavanisagar')) {
  throw new Error('Failed to open spot by Name');
}
console.log('✅ Spot lookup by name opened successfully!');

console.log('\n🎉 ALL SPOT DETAILS MODAL TESTS PASSED!');
process.exit(0);
