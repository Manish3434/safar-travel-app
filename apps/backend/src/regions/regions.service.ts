import { Injectable, Inject, Optional } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike } from 'typeorm';
import Redis from 'ioredis';
import { State } from './entities/state.entity';
import { District } from './entities/district.entity';
import { REDIS_CLIENT } from '../redis/redis.module';
import {
  SearchRegionsDto,
  StateResponseDto,
  DistrictResponseDto,
} from './dto/regions.dto';
import {
  INDIAN_STATES,
  ALL_DISTRICTS_MAP,
} from '../places/data/india_states_districts';

@Injectable()
export class RegionsService {
  private readonly CACHE_TTL = 3600; // 1 hour TTL per Rule 6

  constructor(
    @Optional()
    @InjectRepository(State)
    private readonly stateRepo?: Repository<State>,

    @Optional()
    @InjectRepository(District)
    private readonly districtRepo?: Repository<District>,

    @Optional()
    @Inject(REDIS_CLIENT)
    private readonly redis?: Redis,
  ) {}

  /**
   * Returns all 28 States + 8 Union Territories (36 total).
   * Fully cached with Redis and supports search & type filters.
   */
  async getStates(dto?: SearchRegionsDto): Promise<StateResponseDto[]> {
    const cacheKey = `regions:states:${dto?.type || 'all'}:${dto?.search || 'all'}`;

    // 1. Try Redis Cache
    if (this.redis) {
      try {
        const cached = await this.redis.get(cacheKey);
        if (cached) {
          return JSON.parse(cached);
        }
      } catch {
        // Cache miss or Redis offline, proceed to DB/mock
      }
    }

    let states: StateResponseDto[] = [];

    // 2. Query DB if TypeORM is available
    if (this.stateRepo) {
      try {
        const query = this.stateRepo
          .createQueryBuilder('state')
          .leftJoin('state.districts', 'district')
          .select([
            'state.code AS code',
            'state.name AS name',
            'state.nameLocal AS "nameLocal"',
            'state.type AS type',
            'state.capitalName AS "capitalName"',
            'state.capitalLat AS "capitalLat"',
            'state.capitalLon AS "capitalLon"',
            'state.languages AS languages',
            'state.aliases AS aliases',
            'state.slug AS slug',
            'COUNT(district.lgdCode)::int AS "districtCount"',
          ])
          .groupBy('state.code')
          .orderBy('state.name', 'ASC');

        if (dto?.type) {
          query.andWhere('state.type = :type', { type: dto.type });
        }

        if (dto?.search) {
          query.andWhere(
            '(state.name ILIKE :search OR state.code ILIKE :search OR :search = ANY(state.aliases))',
            { search: `%${dto.search}%` }
          );
        }

        const raw = await query.getRawMany();
        if (raw && raw.length > 0) {
          states = raw.map((r) => ({
            code: r.code,
            name: r.name,
            nameLocal: r.nameLocal,
            type: r.type,
            capitalName: r.capitalName,
            capitalLat: r.capitalLat ? parseFloat(r.capitalLat) : undefined,
            capitalLon: r.capitalLon ? parseFloat(r.capitalLon) : undefined,
            languages: r.languages || [],
            aliases: r.aliases || [],
            slug: r.slug,
            districtCount: r.districtCount || 0,
          }));
        }
      } catch {
        // Database query failed or unmigrated, fall through to in-memory fallback
      }
    }

    // 3. Fallback to canonical in-memory dataset
    if (states.length === 0) {
      states = INDIAN_STATES.map((s) => ({
        code: s.code,
        name: s.name,
        nameLocal: {
          ta: s.name_ta,
          hi: s.name_hi,
        },
        type: (s.type || (['AN', 'CH', 'DN', 'DL', 'JK', 'LA', 'LD', 'PY'].includes(s.code) ? 'union_territory' : 'state')) as 'state' | 'union_territory',
        capitalName: s.capital_name,
        languages: ['English', 'Hindi'],
        aliases: [],
        slug: s.name.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
        districtCount: s.district_count,
      }));

      if (dto?.type) {
        states = states.filter((s) => s.type === dto.type);
      }

      if (dto?.search) {
        const queryTerm = dto.search.toLowerCase();
        states = states.filter(
          (s) =>
            s.name.toLowerCase().includes(queryTerm) ||
            s.code.toLowerCase().includes(queryTerm)
        );
      }
    }

    // 4. Populate Cache
    if (this.redis && states.length > 0) {
      try {
        await this.redis.set(cacheKey, JSON.stringify(states), 'EX', this.CACHE_TTL);
      } catch {
        // Ignore cache set errors
      }
    }

    return states;
  }

  /**
   * Returns canonical districts for a given State or Union Territory.
   */
  async getDistricts(stateCode: string, search?: string): Promise<DistrictResponseDto[]> {
    const code = stateCode.toUpperCase();
    const cacheKey = `regions:districts:${code}:${search || 'all'}`;

    if (this.redis) {
      try {
        const cached = await this.redis.get(cacheKey);
        if (cached) {
          return JSON.parse(cached);
        }
      } catch {}
    }

    let districts: DistrictResponseDto[] = [];

    // 1. Try DB
    if (this.districtRepo) {
      try {
        const query = this.districtRepo
          .createQueryBuilder('district')
          .where('district.stateCode = :code', { code })
          .orderBy('district.name', 'ASC');

        if (search) {
          query.andWhere(
            '(district.name ILIKE :search OR :search = ANY(district.aliases) OR district.headquarters ILIKE :search)',
            { search: `%${search}%` }
          );
        }

        const dbDistricts = await query.getMany();
        if (dbDistricts && dbDistricts.length > 0) {
          districts = dbDistricts.map((d) => ({
            id: d.lgdCode,
            stateCode: d.stateCode,
            name: d.name,
            nameLocal: d.nameLocal,
            aliases: d.aliases,
            headquarters: d.headquarters,
            subdivisionType: d.subdivisionType,
            slug: d.slug,
          }));
        }
      } catch {}
    }

    // 2. Fallback to in-memory ALL_DISTRICTS_MAP
    if (districts.length === 0) {
      const inMem = ALL_DISTRICTS_MAP[code] || [];
      districts = inMem.map((d) => ({
        id: d.id,
        stateCode: d.state_code,
        name: d.name,
        nameLocal: {
          ta: d.name_ta || d.name,
          hi: d.name_hi || d.name,
        },
        aliases: [],
        headquarters: d.headquarters,
        subdivisionType: 'district',
        slug: d.id,
      }));

      if (search) {
        const term = search.toLowerCase();
        districts = districts.filter((d) =>
          d.name.toLowerCase().includes(term) ||
          (d.headquarters && d.headquarters.toLowerCase().includes(term))
        );
      }
    }

    if (this.redis && districts.length > 0) {
      try {
        await this.redis.set(cacheKey, JSON.stringify(districts), 'EX', this.CACHE_TTL);
      } catch {}
    }

    return districts;
  }
}
