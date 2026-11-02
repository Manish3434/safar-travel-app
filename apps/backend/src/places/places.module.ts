import { Module } from '@nestjs/common';
import { TypeOrmModule, getRepositoryToken } from '@nestjs/typeorm';
import { PlacesController } from './places.controller';
import { PlacesService } from './places.service';
import { ProvidersModule } from '../providers/providers.module';
import { Place } from './entities/place.entity';

const isDbActive = process.env.DB_ENABLED === 'true';

@Module({
  imports: [
    ...(isDbActive ? [TypeOrmModule.forFeature([Place])] : []),
    ProvidersModule,
  ],
  controllers: [PlacesController],
  providers: [
    PlacesService,
    ...(!isDbActive
      ? [
          {
            provide: getRepositoryToken(Place),
            useValue: {
              findOne: () => Promise.resolve(null),
              find: () => Promise.resolve([]),
              create: (d: any) => d,
              save: (d: any) => Promise.resolve(d),
            },
          },
        ]
      : []),
  ],
  exports: [PlacesService],
})
export class PlacesModule {}
