import { Controller, Get, Inject } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { REDIS_CLIENT } from '../redis/redis.module';
import Redis from 'ioredis';

@Controller('health')
export class HealthController {
  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    private readonly config: ConfigService,
  ) {}

  @Get()
  async check() {
    let redisStatus = 'offline (fallback active)';
    try {
      const pong = await Promise.race([
        this.redis.ping(),
        new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 500)),
      ]);
      if (pong === 'PONG') redisStatus = 'up';
    } catch {
      // Redis is offline — in-memory fallback active
    }

    const isDbEnabled = this.config.get('DB_ENABLED') === 'true';

    return {
      status: 'ok',
      mode: this.config.get('PROVIDER_MODE', 'mock'),
      db_persistence: isDbEnabled ? 'postgresql' : 'in-memory-mock',
      redis_cache: redisStatus,
      timestamp: new Date().toISOString(),
    };
  }
}
