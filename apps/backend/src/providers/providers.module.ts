import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';

import { PLACES_PROVIDER } from './places/places.provider';
import { MockPlacesProvider } from './places/mock-places.provider';
import { GooglePlacesProvider } from './places/google-places.provider';

import { ROUTES_PROVIDER } from './routes/routes.provider';
import { MockRoutesProvider } from './routes/mock-routes.provider';

import { WEATHER_PROVIDER } from './weather/weather.provider';
import { MockWeatherProvider } from './weather/mock-weather.provider';

import { STAYS_PROVIDER } from './stays/stays.provider';
import { MockStaysProvider } from './stays/mock-stays.provider';

import { TRANSPORT_PROVIDER } from './transport/transport.provider';
import { MockTransportProvider } from './transport/mock-transport.provider';

/**
 * ProvidersModule — factory pattern controlled by PROVIDER_MODE env variable.
 *
 * PROVIDER_MODE=mock  → use in-memory mock implementations (default, safe for CI)
 * PROVIDER_MODE=real  → use live API implementations (requires API keys)
 *
 * All providers are exported so any feature module can inject them by token.
 */
@Module({
  imports: [ConfigModule],
  providers: [
    // ── Places ──────────────────────────────────────────────────────────────
    {
      provide: PLACES_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const mode = config.get<string>('PROVIDER_MODE', 'mock');
        return mode === 'real' ? new GooglePlacesProvider(config) : new MockPlacesProvider();
      },
    },

    // ── Routes ──────────────────────────────────────────────────────────────
    {
      provide: ROUTES_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        // Real implementation (Google Routes API) — add GoogleRoutesProvider when key is ready
        return new MockRoutesProvider();
      },
    },

    // ── Weather ─────────────────────────────────────────────────────────────
    {
      provide: WEATHER_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        // Real implementation (Google Weather API) — add GoogleWeatherProvider when key is ready
        return new MockWeatherProvider();
      },
    },

    // ── Stays ───────────────────────────────────────────────────────────────
    {
      provide: STAYS_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        // Real implementation (Booking.com / Expedia API) — add when approval arrives
        return new MockStaysProvider();
      },
    },

    // ── Transport ───────────────────────────────────────────────────────────
    {
      provide: TRANSPORT_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        // Real implementation — add GTFS import pipeline when data is ready
        return new MockTransportProvider();
      },
    },
  ],
  exports: [
    PLACES_PROVIDER,
    ROUTES_PROVIDER,
    WEATHER_PROVIDER,
    STAYS_PROVIDER,
    TRANSPORT_PROVIDER,
  ],
})
export class ProvidersModule {}
