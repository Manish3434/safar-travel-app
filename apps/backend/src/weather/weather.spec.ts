import { MockWeatherProvider } from '../providers/weather/mock-weather.provider';

describe('MockWeatherProvider', () => {
  let provider: MockWeatherProvider;

  beforeEach(() => {
    provider = new MockWeatherProvider();
  });

  it('should return current weather with realistic temperature and humidity', async () => {
    const current = await provider.getCurrent('tn-001', 12.1, 77.78);
    expect(current.place_id).toBe('tn-001');
    expect(current.temperature_c).toBeGreaterThan(0);
    expect(current.humidity_pct).toBeGreaterThanOrEqual(0);
    expect(current.humidity_pct).toBeLessThanOrEqual(100);
    expect(current.condition).toBeDefined();
    expect(current.source).toBe('mock');
  });

  it('should return 10-day forecast', async () => {
    const forecast = await provider.getForecast('tn-001', 12.1, 77.78);
    expect(forecast.daily.length).toBe(10);
    forecast.daily.forEach((d) => {
      expect(d.date).toBeDefined();
      expect(d.max_c).toBeGreaterThanOrEqual(d.min_c);
      expect(d.condition).toBeDefined();
    });
  });
});
