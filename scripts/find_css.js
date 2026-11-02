const fs = require('fs');
const path = require('path');

const css = fs.readFileSync(path.join(__dirname, '../apps/web/styles.css'), 'utf8');
const lines = css.split('\n');

console.log('--- Search in styles.css ---');
lines.forEach((line, idx) => {
  if (line.includes('calc-mode') || line.includes('spot-calc') || line.includes('mode-chip') || line.includes('map-canvas-container')) {
    console.log(`${idx + 1}: ${line.trim()}`);
  }
});
