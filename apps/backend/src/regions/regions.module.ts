import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { State } from './entities/state.entity';
import { District } from './entities/district.entity';
import { RegionsController } from './regions.controller';
import { RegionsService } from './regions.service';

const isDbActive = process.env.DB_ENABLED === 'true';

@Module({
  imports: [
    ...(isDbActive ? [TypeOrmModule.forFeature([State, District])] : []),
  ],
  controllers: [RegionsController],
  providers: [RegionsService],
  exports: [RegionsService],
})
export class RegionsModule {}
