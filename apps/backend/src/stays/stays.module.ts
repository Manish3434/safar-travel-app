import { Module } from '@nestjs/common';
import { StaysController } from './stays.controller';
import { StaysService } from './stays.service';
import { ProvidersModule } from '../providers/providers.module';
import { PlacesModule } from '../places/places.module';

@Module({
  imports: [ProvidersModule, PlacesModule],
  controllers: [StaysController],
  providers: [StaysService],
})
export class StaysModule {}
