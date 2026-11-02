import { ProviderMeta } from '../places/places.provider';

export interface WeatherCurrent extends ProviderMeta {
  place_id: string;
  temperature_c: number;
  feels_like_c: number;
  humidity_pct: number;
  condition: string; // e.g. "Partly Cloudy"
  condition_icon: string; // URL or icon code
  wind_kmh: number;
  is_approximate: boolean; // true for remote spots
}

export interface WeatherForecastDay {
  date: string; // YYYY-MM-DD
  max_c: number;
  min_c: number;
  condition: string;
  condition_icon: string;
  rain_chance_pct: number;
}

export interface WeatherForecast extends ProviderMeta {
  place_id: string;
  current: WeatherCurrent;
  hourly: { time: string; temp_c: number; condition: string }[];
  daily: WeatherForecastDay[];
  is_approximate: boolean;
}

export interface WeatherProvider {
  getCurrent(placeId: string, lat: number, lng: number): Promise<WeatherCurrent>;
  getForecast(placeId: string, lat: number, lng: number): Promise<WeatherForecast>;
}

export const WEATHER_PROVIDER = 'WEATHER_PROVIDER';
