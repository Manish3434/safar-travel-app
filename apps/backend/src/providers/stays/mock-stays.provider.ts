import { Injectable } from '@nestjs/common';
import { StaysProvider, Stay, StaysFilter } from './stays.provider';

const SEED_STAYS: Record<string, Stay[]> = {
  // Hogenakkal Falls
  'tn-001': [
    { id: 'st-tn001-1', name: 'Hogenakkal River Resort', type: 'resort', price_per_night_inr: 3200, rating: 4.1, distance_km: 1.2, address: 'Hogenakkal Village, Dharmapuri Dist.', amenities: ['AC', 'Restaurant', 'Parking'], source: 'mock', fetched_at: new Date().toISOString() },
    { id: 'st-tn001-2', name: 'Green Valley Homestay', type: 'homestay', price_per_night_inr: 1200, rating: 4.4, distance_km: 0.8, address: 'Hogenakkal Village', amenities: ['Home-cooked meals', 'WiFi'], source: 'mock', fetched_at: new Date().toISOString() },
  ],
  // Ooty
  'tn-002': [
    { id: 'st-tn002-1', name: 'Sterling Ooty Fern Hill', type: 'resort', price_per_night_inr: 7500, rating: 4.5, distance_km: 2.0, address: 'Fern Hill, Ooty 643001', amenities: ['AC', 'Pool', 'Restaurant', 'Spa'], source: 'mock', fetched_at: new Date().toISOString() },
    { id: 'st-tn002-2', name: 'Nilgiri Nest Homestay', type: 'homestay', price_per_night_inr: 1800, rating: 4.6, distance_km: 0.5, address: 'Charring Cross, Ooty', amenities: ['Breakfast included', 'Garden'], source: 'mock', fetched_at: new Date().toISOString() },
    { id: 'st-tn002-3', name: 'Hotel Lakeview', type: 'hotel', price_per_night_inr: 2400, rating: 3.9, distance_km: 1.0, address: 'Boat House Road, Ooty', amenities: ['Restaurant', 'Parking'], source: 'mock', fetched_at: new Date().toISOString() },
  ],
  // Jog Falls
  'ka-001': [
    { id: 'st-ka001-1', name: 'Sharavathi Adventure Camp', type: 'resort', price_per_night_inr: 2800, rating: 4.2, distance_km: 3.0, address: 'Jog Road, Sagara', amenities: ['Tent stays', 'Campfire', 'Trek guides'], source: 'mock', fetched_at: new Date().toISOString() },
    { id: 'st-ka001-2', name: 'KSTDC Hotel Mayura Gerusoppa', type: 'hotel', price_per_night_inr: 1600, rating: 3.7, distance_km: 0.3, address: 'Jog Falls, Karnataka', amenities: ['Restaurant', 'Parking'], source: 'mock', fetched_at: new Date().toISOString() },
  ],
  // Hampi
  'ka-003': [
    { id: 'st-ka003-1', name: 'Evolve Back Hampi', type: 'resort', price_per_night_inr: 18000, rating: 4.8, distance_km: 5.0, address: 'Kamalapura, Hampi', amenities: ['Pool', 'Spa', 'Heritage tours', 'AC'], source: 'mock', fetched_at: new Date().toISOString() },
    { id: 'st-ka003-2', name: 'Hampi Boulders Guesthouse', type: 'lodge', price_per_night_inr: 900, rating: 4.3, distance_km: 0.4, address: 'Virupapur Gaddi, Hampi', amenities: ['Riverside', 'Breakfast'], source: 'mock', fetched_at: new Date().toISOString() },
  ],
  // Ajanta Caves
  'mh-001': [
    { id: 'st-mh001-1', name: 'Hotel Ajanta Ambassador', type: 'hotel', price_per_night_inr: 3500, rating: 4.0, distance_km: 8.0, address: 'Jalgaon Road, Aurangabad', amenities: ['AC', 'Restaurant', 'Pool'], source: 'mock', fetched_at: new Date().toISOString() },
    { id: 'st-mh001-2', name: 'MTDC Ajanta Guest House', type: 'lodge', price_per_night_inr: 1400, rating: 3.6, distance_km: 2.0, address: 'Ajanta T-junction, Aurangabad Dist.', amenities: ['Basic rooms', 'Parking'], source: 'mock', fetched_at: new Date().toISOString() },
  ],
  // Lonavala
  'mh-002': [
    { id: 'st-mh002-1', name: 'The Machan Resort', type: 'resort', price_per_night_inr: 12000, rating: 4.7, distance_km: 4.0, address: 'Lonavala Khandala Road', amenities: ['Treehouse', 'Pool', 'Spa', 'AC'], source: 'mock', fetched_at: new Date().toISOString() },
    { id: 'st-mh002-2', name: 'Sunset View Homestay', type: 'homestay', price_per_night_inr: 2200, rating: 4.5, distance_km: 1.5, address: 'Bhushi Dam Road, Lonavala', amenities: ['Home-cooked food', 'Valley view'], source: 'mock', fetched_at: new Date().toISOString() },
    { id: 'st-mh002-3', name: 'Hotel Chandralok', type: 'hotel', price_per_night_inr: 1800, rating: 3.8, distance_km: 0.3, address: 'Market area, Lonavala', amenities: ['Restaurant', 'Parking'], source: 'mock', fetched_at: new Date().toISOString() },
  ],
};

const DEFAULT_STAYS: Stay[] = [
  { id: 'st-default-1', name: 'Travellers Rest House', type: 'lodge', price_per_night_inr: 1000, rating: 3.5, distance_km: 2.0, address: 'Near the destination', amenities: ['Basic rooms'], source: 'mock', fetched_at: new Date().toISOString() },
];

@Injectable()
export class MockStaysProvider implements StaysProvider {
  async getNearPlace(placeId: string, lat: number, lng: number, filters?: StaysFilter): Promise<Stay[]> {
    let stays = SEED_STAYS[placeId] ?? DEFAULT_STAYS;

    if (filters?.price_max) {
      stays = stays.filter((s) => s.price_per_night_inr <= filters.price_max!);
    }
    if (filters?.rating_min) {
      stays = stays.filter((s) => (s.rating ?? 0) >= filters.rating_min!);
    }
    if (filters?.type) {
      stays = stays.filter((s) => s.type === filters.type);
    }

    return stays;
  }
}
