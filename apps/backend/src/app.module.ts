import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { PlacesModule } from './places/places.module';
import { WeatherModule } from './weather/weather.module';
import { StaysModule } from './stays/stays.module';
import { TransportModule } from './transport/transport.module';
import { SavedPlacesModule } from './saved-places/saved-places.module';
import { ProvidersModule } from './providers/providers.module';
import { HealthModule } from './health/health.module';
import { RedisModule } from './redis/redis.module';

import { RegionsModule } from './regions/regions.module';

const isDbActive = process.env.DB_ENABLED === 'true';

@Module({
  imports: [
    // Config — loads .env, available globally
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // Database — PostgreSQL + PostGIS via TypeORM (active when DB_ENABLED=true)
    ...(isDbActive
      ? [
          TypeOrmModule.forRootAsync({
            inject: [ConfigService],
            useFactory: (config: ConfigService) => ({
              type: 'postgres',
              url: config.get<string>('DATABASE_URL'),
              entities: [__dirname + '/**/*.entity{.ts,.js}'],
              migrations: [__dirname + '/database/migrations/*{.ts,.js}'],
              synchronize: false, // always use migrations, never auto-sync
              logging: config.get('NODE_ENV') === 'development',
              retryAttempts: 2,
              retryDelay: 1000,
            }),
          }),
        ]
      : []),

    // Feature modules
    RedisModule,
    ProvidersModule,
    RegionsModule,
    AuthModule,
    PlacesModule,
    WeatherModule,
    StaysModule,
    TransportModule,
    SavedPlacesModule,
    HealthModule,
  ],
})
export class AppModule {}
