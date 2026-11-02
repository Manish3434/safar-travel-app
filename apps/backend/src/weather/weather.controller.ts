import { Controller, Get, Param } from '@nestjs/common';
import { WeatherService } from './weather.service';

@Controller('places')
export class WeatherController {
  constructor(private readonly weatherService: WeatherService) {}

  /** GET /places/:id/weather */
  @Get(':id/weather')
  getWeather(@Param('id') id: string) {
    return this.weatherService.getForPlace(id);
  }
}
