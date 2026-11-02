import { ProviderMeta } from '../places/places.provider';

export type StayType = 'hotel' | 'lodge' | 'homestay' | 'resort' | 'hostel';

export interface Stay extends ProviderMeta {
  id: string;
  name: string;
  type: StayType;
  price_per_night_inr: number;
  rating?: number;
  distance_km: number;
  address: string;
  phone?: string;
  amenities: string[];
  photo_url?: string;
}

export interface StaysFilter {
  price_max?: number;
  rating_min?: number;
  type?: StayType;
}

export interface StaysProvider {
  getNearPlace(placeId: string, lat: number, lng: number, filters?: StaysFilter): Promise<Stay[]>;
}

export const STAYS_PROVIDER = 'STAYS_PROVIDER';
