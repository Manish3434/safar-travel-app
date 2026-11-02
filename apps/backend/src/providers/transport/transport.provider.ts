import { ProviderMeta } from '../places/places.provider';

export interface BusTrip extends ProviderMeta {
  route_id: string;
  route_name: string;
  operator: string; // e.g. "TNSTC", "KSRTC", "MSRTC"
  from_stop: string;
  to_stop: string;
  departure_time: string; // HH:MM
  arrival_time: string;   // HH:MM
  duration_minutes: number;
  fare_inr?: number;
  bus_type: 'ordinary' | 'express' | 'ac' | 'luxury';
  available: boolean;
  last_updated: string; // ISO 8601 — never omit this
  data_source: string;  // e.g. "TNSTC official schedule - Oct 2026"
}

export interface TransportProvider {
  getRoutes(
    fromStopOrCity: string,
    toStopOrCity: string,
    date?: string, // YYYY-MM-DD
  ): Promise<{ trips: BusTrip[]; available: boolean; reason?: string }>;
}

export const TRANSPORT_PROVIDER = 'TRANSPORT_PROVIDER';
