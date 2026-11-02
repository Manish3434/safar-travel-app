import { Module } from '@nestjs/common';
import { WeatherController } from './weather.controller';
import { WeatherService } from './weather.service';
import { ProvidersModule } from '../providers/providers.module';
import { PlacesModule } from '../places/places.module';

@Module({
  imports: [ProvidersModule, PlacesModule],
  controllers: [WeatherController],
  providers: [WeatherService],
})
export class WeatherModule {}
