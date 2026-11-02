import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { RegionsService } from './regions.service';
import { State } from './entities/state.entity';
import { District } from './entities/district.entity';
import { REDIS_CLIENT } from '../redis/redis.module';
import { ALL_DISTRICTS_MAP } from '../places/data/india_states_districts';

describe('RegionsService', () => {
  let service: RegionsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RegionsService,
        {
          provide: getRepositoryToken(State),
          useValue: null,
        },
        {
          provide: getRepositoryToken(District),
          useValue: null,
        },
        {
          provide: REDIS_CLIENT,
          useValue: null,
        },
      ],
    }).compile();

    service = module.get<RegionsService>(RegionsService);
  });

  describe('getStates()', () => {
    it('should return exactly 36 States and Union Territories in canonical baseline', async () => {
      const states = await service.getStates();
      expect(states).toBeDefined();
      expect(states.length).toBe(36);

      const stateTypes = states.filter((s) => s.type === 'state');
      const utTypes = states.filter((s) => s.type === 'union_territory');

      expect(stateTypes.length).toBe(28);
      expect(utTypes.length).toBe(8);
    });

    it('should filter strictly by type: state', async () => {
      const statesOnly = await service.getStates({ type: 'state' });
      expect(statesOnly.length).toBe(28);
      statesOnly.forEach((s) => expect(s.type).toBe('state'));
    });

    it('should filter strictly by type: union_territory', async () => {
      const utsOnly = await service.getStates({ type: 'union_territory' });
      expect(utsOnly.length).toBe(8);
      utsOnly.forEach((u) => expect(u.type).toBe('union_territory'));

      const utCodes = utsOnly.map((u) => u.code).sort();
      expect(utCodes).toEqual(['AN', 'CH', 'DL', 'DN', 'JK', 'LA', 'LD', 'PY'].sort());
    });

    it('should filter by search query (e.g. Tamil Nadu)', async () => {
      const results = await service.getStates({ search: 'Tamil' });
      expect(results.length).toBe(1);
      expect(results[0].code).toBe('TN');
    });
  });

  describe('getDistricts()', () => {
    it('should return 38 canonical districts for Tamil Nadu (TN)', async () => {
      const districts = await service.getDistricts('TN');
      expect(districts.length).toBe(38);
    });

    it('should return 14 canonical districts for Kerala (KL)', async () => {
      const districts = await service.getDistricts('KL');
      expect(districts.length).toBe(14);
    });

    it('should return 3 canonical districts for Andaman & Nicobar (AN)', async () => {
      const districts = await service.getDistricts('AN');
      expect(districts.length).toBe(3);
      const names = districts.map((d) => d.name);
      expect(names).toContain('Nicobars');
      expect(names).toContain('North and Middle Andaman');
      expect(names).toContain('South Andamans');
    });

    it('should return 1 canonical district for Lakshadweep (LD)', async () => {
      const districts = await service.getDistricts('LD');
      expect(districts.length).toBe(1);
      expect(districts[0].name).toBe('Lakshadweep');
    });

    it('should return 1 canonical district for Chandigarh (CH)', async () => {
      const districts = await service.getDistricts('CH');
      expect(districts.length).toBe(1);
      expect(districts[0].name).toBe('Chandigarh');
    });

    it('should return 3 canonical districts for Dadra and Nagar Haveli and Daman and Diu (DN)', async () => {
      const districts = await service.getDistricts('DN');
      expect(districts.length).toBe(3);
      const names = districts.map((d) => d.name);
      expect(names).toContain('Dadra and Nagar Haveli');
      expect(names).toContain('Daman');
      expect(names).toContain('Diu');
    });

    it('should return 13 canonical districts for Delhi (DL)', async () => {
      const districts = await service.getDistricts('DL');
      expect(districts.length).toBe(13);
    });

    it('should return 2 canonical revenue districts for Puducherry (PY)', async () => {
      const districts = await service.getDistricts('PY');
      expect(districts.length).toBe(2);
      const names = districts.map((d) => d.name);
      expect(names).toContain('Karaikal');
      expect(names).toContain('Puducherry');
    });

    it('should have all 36 keys in ALL_DISTRICTS_MAP with zero duplicates', () => {
      const keys = Object.keys(ALL_DISTRICTS_MAP);
      expect(keys.length).toBe(36);

      const uniqueKeys = new Set(keys);
      expect(uniqueKeys.size).toBe(36);
    });
  });
});
