import { MockTransportProvider } from '../providers/transport/mock-transport.provider';

describe('MockTransportProvider', () => {
  let provider: MockTransportProvider;

  beforeEach(() => {
    provider = new MockTransportProvider();
  });

  it('should return routes for a known city pair', async () => {
    const result = await provider.getRoutes('Chennai', 'Hogenakkal');
    expect(result.available).toBe(true);
    expect(result.trips.length).toBeGreaterThan(0);
    result.trips.forEach((t) => {
      expect(t.last_updated).toBeDefined();
      expect(t.data_source).toBeDefined();
      expect(t.source).toBe('mock');
      // Rule: never guess a timing — operator must always be set
      expect(t.operator).toBeDefined();
    });
  });

  it('should return available=false with reason for unknown route', async () => {
    const result = await provider.getRoutes('XYZCity', 'ABCTown');
    expect(result.available).toBe(false);
    expect(result.reason).toBeDefined();
    expect(result.trips).toHaveLength(0);
  });

  it('should match routes case-insensitively', async () => {
    const result = await provider.getRoutes('mumbai', 'lonavala');
    expect(result.available).toBe(true);
  });

  it('should return routes for Kerala (Kochi - Munnar)', async () => {
    const result = await provider.getRoutes('Kochi', 'Munnar');
    expect(result.available).toBe(true);
    expect(result.trips[0].operator).toBe('KSRTC Kerala');
    expect(result.trips[0].fare_inr).toBe(165);
  });

  it('should return routes for Himachal Pradesh (Delhi - Manali)', async () => {
    const result = await provider.getRoutes('Delhi', 'Manali');
    expect(result.available).toBe(true);
    expect(result.trips[0].operator).toBe('HRTC');
    expect(result.trips[0].bus_type).toBe('ac');
  });

  it('should return routes for Rajasthan (Delhi - Jaipur)', async () => {
    const result = await provider.getRoutes('Delhi', 'Jaipur');
    expect(result.available).toBe(true);
    expect(result.trips[0].operator).toBe('RSRTC');
  });

  it('should return routes for Uttarakhand (Delhi - Rishikesh)', async () => {
    const result = await provider.getRoutes('Delhi', 'Rishikesh');
    expect(result.available).toBe(true);
    expect(result.trips[0].operator).toBe('UTC');
  });
});

describe('TransportService - calculateDistanceAndRoutes', () => {
  it('should calculate distance and multi-modal transport modes correctly', () => {
    const { TransportService } = require('./transport.service');
    const service = new TransportService(new MockTransportProvider());

    const result = service.calculateDistanceAndRoutes({
      origin: 'Coimbatore',
      destination: 'Parunthumpara',
      originLat: 11.0168,
      originLng: 76.9558,
      destLat: 9.605,
      destLng: 77.01
    });

    expect(result.success).toBe(true);
    expect(result.distanceKm).toBeGreaterThan(50);
    expect(result.modes).toBeDefined();
    expect(result.modes.car.duration).toBeDefined();
    expect(result.modes.bike.duration).toBeDefined();
    expect(result.modes.walk.duration).toBeDefined();
    expect(result.modes.flight.duration).toBeDefined();
    expect(result.modes.train.duration).toBeDefined();
    expect(result.googleMapsUrl).toContain('https://www.google.com/maps/dir');
  });
});
