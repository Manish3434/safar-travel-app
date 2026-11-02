import { IndianState, District } from '../../places/data/india_states_districts';

/** Shared field added to every response that comes from a third-party provider */
export interface ProviderMeta {
  source: string;
  fetched_at: string; // ISO 8601
}

/** Coordinates */
export interface LatLng {
  lat: number;
  lng: number;
}

/** Minimal place summary used in search results and nearby lists */
export interface PlaceResult extends ProviderMeta {
  id: string;
  name: string;
  name_ta?: string; // Tamil
  name_hi?: string; // Hindi
  category: string;
  state_code?: string;
  state_name?: string;
  district_id?: string;
  district_name?: string;
  main_photo_url?: string;
  distance_km?: number;
  rating?: number;
  description: string;
  location: LatLng;
  sensitive: boolean;
}

/** Full place detail returned from GET /places/:id */
export interface PlaceDetail extends PlaceResult {
  photos: string[];
  opening_hours?: string;
  how_to_reach?: string;
  nearby_places?: PlaceResult[];
  permit_required: boolean;
  guide_required: boolean;
  difficulty?: 'easy' | 'moderate' | 'hard';
  best_season?: string;
  network_info?: string;
  warnings?: string[];
  nearest_road?: string;
  nearest_hospital?: string;
}

/** Interface every places provider must implement */
export interface PlacesProvider {
  getStates(): Promise<IndianState[]>;
  getDistricts(stateCode: string): Promise<District[]>;
  getPlacesByDistrict(districtId: string, category?: string): Promise<PlaceResult[]>;
  search(
    query: string,
    lat?: number,
    lng?: number,
    state?: string,
    district?: string,
    category?: string,
  ): Promise<PlaceResult[]>;
  getById(id: string): Promise<PlaceDetail | null>;
  getNearby(
    lat: number,
    lng: number,
    radius: number,
    category?: string,
  ): Promise<PlaceResult[]>;
}

export const PLACES_PROVIDER = 'PLACES_PROVIDER';
