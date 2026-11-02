const https = require('https');

const url = 'https://api.open-meteo.com/v1/forecast?latitude=11.3410&longitude=77.7172&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m&hourly=precipitation_probability,uv_index&timezone=auto';

https.get(url, (res) => {
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => {
    try {
      const data = JSON.parse(body);
      console.log('Open-Meteo Current Exact:');
      console.log(data.current);

      // Current hour matching
      const nowIsoHour = data.current.time.slice(0, 13) + ':00';
      const idx = data.hourly.time.indexOf(nowIsoHour);
      console.log('Matched Hour Index:', idx, 'for hour:', nowIsoHour);
      console.log('Live Rain Probability:', data.hourly.precipitation_probability[idx] + '%');
      console.log('Live UV Index:', data.hourly.uv_index[idx]);
    } catch(e) {
      console.error(e);
    }
  });
}).on('error', console.error);
