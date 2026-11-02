import { Module } from '@nestjs/common';
import { TypeOrmModule, getRepositoryToken } from '@nestjs/typeorm';
import { SavedPlacesController } from './saved-places.controller';
import { SavedPlacesService } from './saved-places.service';
import { SavedPlace } from './entities/saved-place.entity';

const isDbActive = process.env.DB_ENABLED === 'true';

@Module({
  imports: [
    ...(isDbActive ? [TypeOrmModule.forFeature([SavedPlace])] : []),
  ],
  controllers: [SavedPlacesController],
  providers: [
    SavedPlacesService,
    ...(!isDbActive
      ? [
          {
            provide: getRepositoryToken(SavedPlace),
            useValue: {
              find: () => Promise.resolve([]),
              findOne: () => Promise.resolve(null),
              create: (d: any) => d,
              save: (d: any) => Promise.resolve(d),
              delete: () => Promise.resolve({ affected: 1 }),
            },
          },
        ]
      : []),
  ],
  exports: [SavedPlacesService],
})
export class SavedPlacesModule {}
