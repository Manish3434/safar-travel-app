const fs = require('fs');
const path = require('path');

const appJs = fs.readFileSync(path.join(__dirname, '../apps/web/app.js'), 'utf8');
const lines = appJs.split('\n');

console.log('--- Occurrences of findSpotById in app.js ---');
lines.forEach((line, idx) => {
  if (line.includes('findSpotById')) {
    console.log(`${idx + 1}: ${line.trim()}`);
  }
});

console.log('\n--- Checking Category Showcase Spot Clicks ---');
lines.forEach((line, idx) => {
  if (line.includes('displayCategoryShowcase') || line.includes('showcase-spot-card') || line.includes('renderCategoryShowcase')) {
    console.log(`${idx + 1}: ${line.trim()}`);
  }
});
