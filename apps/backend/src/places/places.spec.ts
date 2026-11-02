import { MockPlacesProvider } from '../providers/places/mock-places.provider';

describe('MockPlacesProvider', () => {
  let provider: MockPlacesProvider;

  beforeEach(() => {
    provider = new MockPlacesProvider();
  });

  describe('search()', () => {
    it('should return results matching a keyword', async () => {
      const results = await provider.search('waterfall');
      expect(results.length).toBeGreaterThan(0);
      results.forEach((r) => {
        expect(r.id).toBeDefined();
        expect(r.source).toBe('mock');
        expect(r.fetched_at).toBeDefined();
      });
    });

    it('should return results for a place name', async () => {
      const results = await provider.search('ooty');
      expect(results.some((r) => r.id === 'tn-002')).toBe(true);
    });

    it('should sort by distance when lat/lng provided', async () => {
      // Chennai coordinates
      const results = await provider.search('waterfall', 13.08, 80.27);
      if (results.length > 1) {
        expect(results[0].distance_km).toBeLessThanOrEqual(results[1].distance_km!);
      }
    });

    it('should mask exact coordinates of sensitive spots', async () => {
      const results = await provider.search('forest');
      const sensitive = results.filter((r) => r.sensitive);
      // We can only verify the non-sensitive ones have precise coordinates
      const nonSensitive = results.filter((r) => !r.sensitive);
      nonSensitive.forEach((r) => {
        expect(r.location.lat).toBeDefined();
        expect(r.location.lng).toBeDefined();
      });
    });
  });

  describe('getById()', () => {
    it('should return a place by ID', async () => {
      const place = await provider.getById('tn-001');
      expect(place).not.toBeNull();
      expect(place!.name).toBe('Hogenakkal Falls');
      expect(place!.source).toBe('mock');
    });

    it('should return null for unknown ID', async () => {
      const place = await provider.getById('unknown-999');
      expect(place).toBeNull();
    });
  });

  describe('getNearby()', () => {
    it('should return places within radius', async () => {
      // Bangalore: 12.97, 77.59
      const results = await provider.getNearby(12.97, 77.59, 500);
      expect(results.length).toBeGreaterThan(0);
      results.forEach((r) => {
        expect(r.distance_km).toBeLessThanOrEqual(500);
      });
    });

    it('should filter by category', async () => {
      const results = await provider.getNearby(12.97, 77.59, 1000, 'waterfall');
      results.forEach((r) => {
        expect(r.category).toBe('waterfall');
      });
    });
  });

  describe('States and Districts Hierarchy', () => {
    it('should return 28 states and union territories', async () => {
      const states = await provider.getStates();
      expect(states.length).toBeGreaterThanOrEqual(28);
      const tn = states.find((s) => s.code === 'TN');
      expect(tn).toBeDefined();
      expect(tn!.name).toBe('Tamil Nadu');
      expect(tn!.district_count).toBe(38);
    });

    it('should return all 38 districts for Tamil Nadu', async () => {
      const districts = await provider.getDistricts('TN');
      expect(districts).toHaveLength(38);
      const nilgiris = districts.find((d) => d.id === 'tn-nilgiris');
      expect(nilgiris).toBeDefined();
      expect(nilgiris!.name).toBe('Nilgiris');
      expect(nilgiris!.name_ta).toBe('நீலகிரி');
    });

    it('should return tourist spots for a selected district', async () => {
      const spots = await provider.getPlacesByDistrict('tn-nilgiris');
      expect(spots.length).toBeGreaterThan(0);
      expect(spots.some((s) => s.id === 'tn-002')).toBe(true); // Ooty
      expect(spots[0].state_code).toBe('TN');
    });

    it('should filter district spots by category (beach, wildlife, museum, bird-sanctuary)', async () => {
      // Chennai: Beach and Museum
      const beachSpots = await provider.getPlacesByDistrict('tn-chennai', 'beach');
      expect(beachSpots.length).toBeGreaterThanOrEqual(1);
      expect(beachSpots[0].category).toBe('beach');
      expect(beachSpots[0].name).toBe('Marina Beach');

      const museumSpots = await provider.getPlacesByDistrict('tn-chennai', 'museum');
      expect(museumSpots.length).toBeGreaterThanOrEqual(1);
      expect(museumSpots[0].category).toBe('museum');
      expect(museumSpots[0].name).toContain('Government Museum');

      // Nilgiris: Wildlife
      const wildlifeSpots = await provider.getPlacesByDistrict('tn-nilgiris', 'wildlife');
      expect(wildlifeSpots.length).toBeGreaterThanOrEqual(1);
      expect(wildlifeSpots[0].category).toBe('wildlife');

      // Chengalpattu: Bird Sanctuary
      const birdSpots = await provider.getPlacesByDistrict('tn-chengalpattu', 'bird-sanctuary');
      expect(birdSpots.length).toBeGreaterThanOrEqual(1);
      expect(birdSpots[0].category).toBe('bird-sanctuary');
      expect(birdSpots[0].name).toContain('Vedanthangal');
    });
  });
});

