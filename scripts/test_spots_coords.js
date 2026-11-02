const { ALL_INDIA_SPOTS } = require('../apps/web/all_india_spots.js');
console.log('Total spots:', ALL_INDIA_SPOTS.length);
const kohima = ALL_INDIA_SPOTS.filter(s => s.districtId === 'nl-kohima');
console.log('Kohima spots count:', kohima.length);
console.log('First Kohima spot:', JSON.stringify(kohima[0], null, 2));

const kangra = ALL_INDIA_SPOTS.filter(s => s.districtId === 'hp-kangra');
console.log('Kangra spots count:', kangra.length);
console.log('First Kangra spot:', JSON.stringify(kangra[0], null, 2));

const belagavi = ALL_INDIA_SPOTS.filter(s => s.districtId === 'ka-belagavi');
console.log('Belagavi spots count:', belagavi.length);
console.log('First Belagavi spot:', JSON.stringify(belagavi[0], null, 2));
