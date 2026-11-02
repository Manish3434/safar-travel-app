import { ProviderMeta } from '../places/places.provider';

export interface RouteResult extends ProviderMeta {
  origin_id: string;
  destination_id: string;
  distance_km: number;
  duration_minutes: number;
  type: 'road' | 'approximate';
  polyline?: string; // encoded polyline for map display
}

export interface RoutesProvider {
  getDistance(
    originLat: number,
    originLng: number,
    destLat: number,
    destLng: number,
  ): Promise<RouteResult>;
}

export const ROUTES_PROVIDER = 'ROUTES_PROVIDER';
