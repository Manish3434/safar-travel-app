import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  PlacesProvider,
  PlaceResult,
  PlaceDetail,
} from './places.provider';

/**
 * Real Google Places API implementation.
 * Only activated when PROVIDER_MODE=real and GOOGLE_PLACES_API_KEY is set.
 * Server-side only — the Flutter app never holds the API key.
 */
@Injectable()
export class GooglePlacesProvider implements PlacesProvider {
  private readonly logger = new Logger(GooglePlacesProvider.name);
  private readonly apiKey: string;
  private readonly baseUrl = 'https://places.googleapis.com/v1';

  constructor(private readonly config: ConfigService) {
    this.apiKey = config.get<string>('GOOGLE_PLACES_API_KEY', '');
  }

  async getStates() {
    return [];
  }

  async getDistricts(stateCode: string) {
    return [];
  }

  async getPlacesByDistrict(districtId: string, category?: string): Promise<PlaceResult[]> {
    return [];
  }

  async search(query: string, lat?: number, lng?: number, state?: string, district?: string, category?: string): Promise<PlaceResult[]> {
    // TODO: implement Google Places Text Search API call
    // Docs: https://developers.google.com/maps/documentation/places/web-service/text-search
    this.logger.warn('GooglePlacesProvider.search: not yet implemented — returning empty');
    return [];
  }

  async getById(id: string): Promise<PlaceDetail | null> {
    // TODO: implement Google Places Details API call
    // Only store place IDs long-term (not full data) per Google ToS
    this.logger.warn('GooglePlacesProvider.getById: not yet implemented — returning null');
    return null;
  }

  async getNearby(lat: number, lng: number, radius: number, category?: string): Promise<PlaceResult[]> {
    // TODO: implement Google Places Nearby Search API call
    this.logger.warn('GooglePlacesProvider.getNearby: not yet implemented — returning empty');
    return [];
  }
}
