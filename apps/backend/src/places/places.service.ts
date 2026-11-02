import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PLACES_PROVIDER, PlacesProvider, PlaceDetail } from '../providers/places/places.provider';
import { ROUTES_PROVIDER, RoutesProvider } from '../providers/routes/routes.provider';
import { Place } from './entities/place.entity';

@Injectable()
export class PlacesService {
  constructor(
    @Inject(PLACES_PROVIDER) private readonly places: PlacesProvider,
    @Inject(ROUTES_PROVIDER) private readonly routes: RoutesProvider,
    @InjectRepository(Place) private readonly placeRepo: Repository<Place>,
  ) {}

  async getStates() {
    return this.places.getStates();
  }

  async getDistricts(stateCode: string) {
    return this.places.getDistricts(stateCode);
  }

  async getPlacesByDistrict(districtId: string, category?: string) {
    return this.places.getPlacesByDistrict(districtId, category);
  }

  async search(
    query: string,
    lat?: number,
    lng?: number,
    state?: string,
    district?: string,
    category?: string,
  ) {
    return this.places.search(query, lat, lng, state, district, category);
  }

  async getById(id: string): Promise<PlaceDetail> {
    try {
      const dbPlace = await this.placeRepo.findOne({ where: { id } });
      if (dbPlace) {
        // GeoJSON coordinate order is [longitude, latitude]
        const coords = dbPlace.location?.coordinates;
        let lat = coords ? coords[1] : 0;
        let lng = coords ? coords[0] : 0;

        // Rule 8: Mask coordinates for sensitive/ecological spots
        if (dbPlace.sensitive) {
          lat = Math.round((lat + 0.02) * 100) / 100;
          lng = Math.round((lng + 0.02) * 100) / 100;
        }

        return {
          id: dbPlace.id,
          name: dbPlace.name,
          name_ta: dbPlace.nameTa,
          name_hi: dbPlace.nameHi,
          category: dbPlace.category,
          state_code: dbPlace.stateCode,
          state_name: dbPlace.stateName,
          district_id: dbPlace.districtId,
          district_name: dbPlace.districtName,
          main_photo_url: dbPlace.mainPhotoUrl,
          photos: dbPlace.photos ?? [],
          rating: dbPlace.rating ? Number(dbPlace.rating) : undefined,
          description: dbPlace.description,
          location: { lat, lng },
          sensitive: dbPlace.sensitive,
          permit_required: dbPlace.permitRequired,
          guide_required: dbPlace.guideRequired,
          difficulty: dbPlace.difficulty,
          best_season: dbPlace.bestSeason,
          how_to_reach: dbPlace.howToReach,
          opening_hours: dbPlace.openingHours,
          network_info: dbPlace.networkInfo,
          warnings: dbPlace.warnings ?? [],
          nearest_road: dbPlace.nearestRoad,
          nearest_hospital: dbPlace.nearestHospital,
          source: dbPlace.source,
          fetched_at: dbPlace.updatedAt ? dbPlace.updatedAt.toISOString() : new Date().toISOString(),
        };
      }
    } catch {
      // In case of database error, fall through to provider
    }

    const place = await this.places.getById(id);
    if (!place) throw new NotFoundException(`Place not found: ${id}`);
    return place;
  }

  getNearby(lat: number, lng: number, radius: number, category?: string) {
    return this.places.getNearby(lat, lng, radius, category);
  }

  async getDistance(placeId: string, userLat: number, userLng: number) {
    const place = await this.getById(placeId);
    return this.routes.getDistance(
      userLat,
      userLng,
      place.location.lat,
      place.location.lng,
    );
  }
}
