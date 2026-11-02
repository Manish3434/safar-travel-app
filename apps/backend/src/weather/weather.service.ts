import { Injectable, Inject } from '@nestjs/common';
import { WEATHER_PROVIDER, WeatherProvider } from '../providers/weather/weather.provider';
import { PlacesService } from '../places/places.service';

@Injectable()
export class WeatherService {
  constructor(
    @Inject(WEATHER_PROVIDER) private readonly weather: WeatherProvider,
    private readonly places: PlacesService,
  ) {}

  async getForPlace(placeId: string) {
    const place = await this.places.getById(placeId);
    return this.weather.getForecast(placeId, place.location.lat, place.location.lng);
  }
}
