const fs = require('fs');
const path = require('path');
const vm = require('vm');

console.log('--- 1. Testing HTML Elements for Live Weather ---');
const html = fs.readFileSync(path.join(__dirname, '../apps/web/index.html'), 'utf8');

const requiredElements = [
  'weatherModal',
  'weatherModalSubtitle',
  'weatherSimulationAlert',
  'btnWeatherModeAuto',
  'btnWeatherModeSummer',
  'btnWeatherModeRain',
  'btnWeatherModeCloudy',
  'btnWeatherModeWinter',
  'weatherHeroCard',
  'weatherHourlyStrip',
  'weatherMetricHumidity',
  'weatherMetricRain',
  'weatherMetricWind',
  'weatherMetricUv',
  'weatherAdvisoryCard',
  'weather-refresh-btn'
];

requiredElements.forEach(elem => {
  if (html.includes(elem)) {
    console.log(`✅ Element found: ${elem}`);
  } else {
    console.error(`❌ Missing element: ${elem}`);
    process.exit(1);
  }
});

console.log('\n--- 2. Testing Live Weather Fetch for Erode, Tamil Nadu ---');
const sandbox = {
  window: {
    addEventListener: () => {},
    removeEventListener: () => {}
  },
  document: {
    getElementById: () => ({
      textContent: '',
      innerHTML: '',
      style: {},
      classList: { add: () => {}, remove: () => {}, toggle: () => {} },
      appendChild: () => {},
      removeChild: () => {}
    }),
    createElement: () => ({
      className: '',
      innerHTML: '',
      style: {},
      appendChild: () => {},
      remove: () => {}
    }),
    querySelectorAll: () => [],
    addEventListener: () => {},
    removeEventListener: () => {},
    body: { style: {}, appendChild: () => {} }
  },
  navigator: {},
  localStorage: { getItem: () => null, setItem: () => {} },
  fetch: global.fetch || require('node-fetch'),
  console: console,
  setTimeout: setTimeout,
  clearTimeout: clearTimeout,
  AbortController: AbortController,
  addEventListener: () => {},
  removeEventListener: () => {}
};
sandbox.window.window = sandbox.window;
sandbox.window.document = sandbox.document;

const appJs = fs.readFileSync(path.join(__dirname, '../apps/web/app.js'), 'utf8');
vm.createContext(sandbox);
vm.runInContext(appJs, sandbox);

async function testWeather() {
  await sandbox.window.fetchWeatherForLocation(11.3410, 77.7172, 'Erode, Tamil Nadu');
  const d = sandbox.window.getCurrentWeatherData();

  console.log('Detected Location:', d.locationName);
  console.log('Temperature:', d.temp + '°C');
  console.log('Condition:', d.condition);
  console.log('Season:', d.season);
  console.log('Humidity:', d.humidity + '%');
  console.log('Rain Chance:', d.rainChance + '%');
  console.log('UV Index:', d.uvIndex);
  console.log('Wind Speed:', d.windSpeed + ' km/h');
  console.log('Feels Like:', d.feelsLike + '°C');
  console.log('Hourly Forecast Items:', d.upcomingForecast?.length);

  // Assertions for realistic daytime live metrics
  if (d.humidity > 85) {
    throw new Error(`Expected daytime humidity around 50-70%, got midnight value ${d.humidity}%`);
  }
  if (d.rainChance > 50 && d.condition.includes('Clear')) {
    throw new Error(`Inconsistent rain chance ${d.rainChance}% with Clear condition`);
  }
  if (!d.season.includes('Post-Monsoon') && !d.season.includes('Autumn')) {
    throw new Error(`Expected Post-Monsoon / Autumn season for November, got: ${d.season}`);
  }
  if (!d.upcomingForecast || d.upcomingForecast.length === 0) {
    throw new Error('Missing upcoming forecast intervals');
  }

  console.log('\n--- 3. Testing Simulation Toggle ---');
  sandbox.window.setSimulatedWeather('summer');
  const dSummer = sandbox.window.getCurrentWeatherData();
  if (dSummer.temp !== 34 || !dSummer.isManualSimulation) {
    throw new Error('Simulation summer mode failed');
  }
  console.log('✅ Simulation Summer Mode set successfully');

  sandbox.window.setSimulatedWeather('auto');
  const dAuto = sandbox.window.getCurrentWeatherData();
  if (dAuto.isManualSimulation) {
    throw new Error('Reverting to auto live mode failed');
  }
  console.log('✅ Revert to Live Auto Mode verified');

  console.log('\n🎉 ALL LIVE WEATHER INTEGRATION TESTS PASSED!');
  process.exit(0);
}

testWeather().catch(e => {
  console.error('Weather Test Error:', e);
  process.exit(1);
});
