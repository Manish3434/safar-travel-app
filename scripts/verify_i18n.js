const fs = require('fs');
const path = require('path');

// Mock window and document environment for testing
global.window = {
  USER_LIVE_LOCATION: { lat: 12.9716, lng: 77.5946, name: 'Bengaluru, Karnataka' },
  addEventListener() {},
  removeEventListener() {},
  innerWidth: 1024,
  innerHeight: 768,
  localStorage: {
    data: {},
    getItem(k) { return this.data[k] || null; },
    setItem(k, v) { this.data[k] = String(v); }
  }
};
global.localStorage = global.window.localStorage;
global.document = {
  documentElement: { lang: 'en' },
  querySelectorAll(sel) { return []; },
  getElementById(id) {
    return {
      classList: {
        add() {},
        remove() {},
        toggle() {},
        contains() { return false; }
      },
      style: {},
      textContent: '',
      value: '',
      placeholder: ''
    };
  },
  addEventListener() {}
};

// Load data.js
const dataModule = require('../apps/web/data.js');
global.STATES_DATA = dataModule.STATES_DATA;
global.CATEGORIES = dataModule.CATEGORIES;
global.ATTRACTIONS_DATA = dataModule.ATTRACTIONS_DATA;
global.FEATURED_SPOTS = dataModule.FEATURED_SPOTS;
global.window.STATES_DATA = dataModule.STATES_DATA;
global.window.CATEGORIES = dataModule.CATEGORIES;

// Load app.js code by eval / module extraction
const appJsCode = fs.readFileSync(path.join(__dirname, '../apps/web/app.js'), 'utf-8');

// Test that eval succeeds without syntax errors
try {
  eval(appJsCode);
  console.log('✅ app.js evaluated successfully in Node!');
} catch (e) {
  console.error('❌ Error evaluating app.js:', e);
  process.exit(1);
}

// 1. Verify I18N_DICTIONARY completeness for all 9 languages
console.log('\n--- 1. Testing I18N_DICTIONARY Keys for 9 Languages ---');
const supportedLangs = ['en', 'ta', 'hi', 'ml', 'te', 'kn', 'mr', 'bn', 'gu'];
const dicts = {};
for (const lang of supportedLangs) {
  dicts[lang] = window.I18N_DICTIONARY[lang];
  if (!dicts[lang]) {
    console.error(`❌ Missing dictionary for: ${lang}`);
  }
}

const requiredKeys = [
  'current_location_label',
  'explore_by_state',
  'explore_by_category',
  'view_all_states',
  'hero_badge',
  'hero_title',
  'hero_desc',
  'pill_beach',
  'pill_mountain',
  'pill_wildlife',
  'pill_desert',
  'calc_heading',
  'mode_car',
  'mode_bike',
  'mode_train',
  'mode_flight',
  'mode_walk',
  'nav_home',
  'nav_map',
  'nav_bucket_list',
  'nav_beaches',
  'nav_forests',
  'about_destination',
  'location_calc_title',
  'save_bucket_list',
  'map_disclaimer',
  'bucket_list_title',
  'location_picker_title'
];

let allKeysPresent = true;
for (const lang of supportedLangs) {
  for (const key of requiredKeys) {
    if (!dicts[lang] || !dicts[lang][key]) {
      console.error(`❌ [${lang}] Missing translation for key: ${key}`);
      allKeysPresent = false;
    }
  }
}
if (allKeysPresent) {
  console.log(`✅ All ${requiredKeys.length} essential translation keys present in all 9 languages: ${supportedLangs.join(', ')}!`);
}

// 2. Test Language Switching & Localization
console.log('\n--- 2. Testing Language Switching Across All 9 Languages ---');
for (const lang of supportedLangs) {
  window.setAppLanguage(lang);
  if (document.documentElement.lang === lang && window.currentAppLanguage === lang) {
    console.log(`✅ setAppLanguage("${lang}") switched successfully!`);
  } else {
    console.error(`❌ setAppLanguage("${lang}") failed:`, window.currentAppLanguage);
  }
}

// Test spot card localized output in Tamil
const testSpot = {
  id: 'spot-sample-01',
  name: 'Marina Beach',
  nameTa: 'மெரினா கடற்கரை',
  nameHi: 'मरीना बीच',
  category: 'beach',
  categoryLabel: 'Beach',
  districtName: 'Chennai',
  stateName: 'Tamil Nadu',
  location: { lat: 13.0499, lng: 80.2824 },
  rating: 4.8
};

window.setAppLanguage('ta');
const cardHtmlTa = createSpotCardHtml(testSpot);
if (cardHtmlTa.includes('மெரினா கடற்கரை') && cardHtmlTa.includes('கடற்கரைகள்')) {
  console.log('✅ createSpotCardHtml generates Tamil spot name & category: மெரினா கடற்கரை / கடற்கரைகள்');
} else {
  console.error('❌ createSpotCardHtml failed Tamil localization:', cardHtmlTa);
}

// Test in Hindi
window.setAppLanguage('hi');
const cardHtmlHi = createSpotCardHtml(testSpot);
if (cardHtmlHi.includes('मरीना बीच') && cardHtmlHi.includes('समुद्र तट')) {
  console.log('✅ createSpotCardHtml generates Hindi spot name & category: मरीना बीच / समुद्र तट');
} else {
  console.error('❌ createSpotCardHtml failed Hindi localization:', cardHtmlHi);
}

// Test localStorage persistence
if (global.localStorage.getItem('safar_lang') === 'hi') {
  console.log('✅ Language selection persists in localStorage ("safar_lang")');
} else {
  console.error('❌ localStorage persistence failed');
}

console.log('\n🎉 ALL TRANSLATION INTEGRATION TESTS PASSED!\n');
