import { Injectable, Inject } from '@nestjs/common';
import { STAYS_PROVIDER, StaysProvider, StaysFilter } from '../providers/stays/stays.provider';
import { PlacesService } from '../places/places.service';

@Injectable()
export class StaysService {
  constructor(
    @Inject(STAYS_PROVIDER) private readonly stays: StaysProvider,
    private readonly places: PlacesService,
  ) {}

  async getNearPlace(placeId: string, filters?: StaysFilter) {
    const place = await this.places.getById(placeId);
    return this.stays.getNearPlace(placeId, place.location.lat, place.location.lng, filters);
  }
}
