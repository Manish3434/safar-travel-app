import { MockStaysProvider } from '../providers/stays/mock-stays.provider';

describe('MockStaysProvider', () => {
  let provider: MockStaysProvider;

  beforeEach(() => {
    provider = new MockStaysProvider();
  });

  it('should return stays for a known place', async () => {
    const stays = await provider.getNearPlace('tn-002', 11.41, 76.69);
    expect(stays.length).toBeGreaterThan(0);
    stays.forEach((s) => {
      expect(s.id).toBeDefined();
      expect(s.name).toBeDefined();
      expect(s.price_per_night_inr).toBeGreaterThan(0);
      expect(s.source).toBe('mock');
      expect(s.fetched_at).toBeDefined();
    });
  });

  it('should filter stays by max price', async () => {
    const stays = await provider.getNearPlace('tn-002', 11.41, 76.69, { price_max: 2000 });
    expect(stays.length).toBeGreaterThan(0);
    stays.forEach((s) => {
      expect(s.price_per_night_inr).toBeLessThanOrEqual(2000);
    });
  });

  it('should filter stays by type', async () => {
    const stays = await provider.getNearPlace('tn-002', 11.41, 76.69, { type: 'homestay' });
    stays.forEach((s) => {
      expect(s.type).toBe('homestay');
    });
  });

  it('should return default fallback stays for an unknown place', async () => {
    const stays = await provider.getNearPlace('unknown-place-999', 12.0, 78.0);
    expect(stays.length).toBeGreaterThan(0);
  });
});
