import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { PlacesService } from './places.service';
import { Place } from './entities/place.entity';
import { PLACES_PROVIDER } from '../providers/places/places.provider';
import { ROUTES_PROVIDER } from '../providers/routes/routes.provider';

describe('PlacesService', () => {
  let service: PlacesService;
  let mockPlaceRepo: any;
  let mockPlacesProvider: any;
  let mockRoutesProvider: any;

  beforeEach(async () => {
    mockPlaceRepo = {
      findOne: jest.fn(),
    };

    mockPlacesProvider = {
      search: jest.fn(),
      getById: jest.fn(),
      getNearby: jest.fn(),
    };

    mockRoutesProvider = {
      getDistance: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PlacesService,
        {
          provide: getRepositoryToken(Place),
          useValue: mockPlaceRepo,
        },
        {
          provide: PLACES_PROVIDER,
          useValue: mockPlacesProvider,
        },
        {
          provide: ROUTES_PROVIDER,
          useValue: mockRoutesProvider,
        },
      ],
    }).compile();

    service = module.get<PlacesService>(PlacesService);
  });

  describe('getById()', () => {
    it('should return place from database when present', async () => {
      mockPlaceRepo.findOne.mockResolvedValue({
        id: 'tn-001',
        name: 'Hogenakkal Falls',
        category: 'waterfall',
        description: 'Scenic waterfall',
        location: { type: 'Point', coordinates: [77.7897, 12.1056] },
        sensitive: false,
        permitRequired: false,
        guideRequired: false,
        source: 'seed',
        updatedAt: new Date(),
      });

      const result = await service.getById('tn-001');
      expect(result.id).toBe('tn-001');
      expect(result.name).toBe('Hogenakkal Falls');
      expect(result.location.lat).toBe(12.1056);
      expect(result.location.lng).toBe(77.7897);
    });

    it('should mask coordinates for sensitive places per Rule 8', async () => {
      mockPlaceRepo.findOne.mockResolvedValue({
        id: 'ka-004',
        name: 'Kudremukh National Park',
        category: 'forest',
        description: 'Lush shola-grassland',
        location: { type: 'Point', coordinates: [75.2396, 13.1872] },
        sensitive: true,
        permitRequired: true,
        guideRequired: true,
        source: 'seed',
        updatedAt: new Date(),
      });

      const result = await service.getById('ka-004');
      expect(result.sensitive).toBe(true);
      // Coordinates should be rounded / shifted for privacy
      expect(result.location.lat).not.toBe(13.1872);
      expect(result.location.lng).not.toBe(75.2396);
    });

    it('should fallback to provider if not in database', async () => {
      mockPlaceRepo.findOne.mockResolvedValue(null);
      mockPlacesProvider.getById.mockResolvedValue({
        id: 'tn-002',
        name: 'Ooty',
        location: { lat: 11.41, lng: 76.69 },
      });

      const result = await service.getById('tn-002');
      expect(result.name).toBe('Ooty');
      expect(mockPlacesProvider.getById).toHaveBeenCalledWith('tn-002');
    });

    it('should throw NotFoundException if neither DB nor provider finds the place', async () => {
      mockPlaceRepo.findOne.mockResolvedValue(null);
      mockPlacesProvider.getById.mockResolvedValue(null);

      await expect(service.getById('unknown')).rejects.toThrow(NotFoundException);
    });
  });

  describe('getDistance()', () => {
    it('should calculate distance via routes provider', async () => {
      mockPlaceRepo.findOne.mockResolvedValue({
        id: 'tn-001',
        location: { type: 'Point', coordinates: [77.7897, 12.1056] },
        sensitive: false,
      });

      mockRoutesProvider.getDistance.mockResolvedValue({
        distance_km: 180,
        duration_minutes: 240,
      });

      const distance = await service.getDistance('tn-001', 13.08, 80.27);
      expect(distance).toEqual({ distance_km: 180, duration_minutes: 240 });
      expect(mockRoutesProvider.getDistance).toHaveBeenCalledWith(13.08, 80.27, 12.1056, 77.7897);
    });
  describe('States and Districts exploration', () => {
    it('should delegate getStates to places provider', async () => {
      mockPlacesProvider.getStates = jest.fn().mockResolvedValue([
        { code: 'TN', name: 'Tamil Nadu', district_count: 38, spot_count: 4 },
      ]);

      const states = await service.getStates();
      expect(states).toHaveLength(1);
      expect(states[0].code).toBe('TN');
      expect(mockPlacesProvider.getStates).toHaveBeenCalled();
    });

    it('should delegate getDistricts to places provider', async () => {
      mockPlacesProvider.getDistricts = jest.fn().mockResolvedValue([
        { id: 'tn-nilgiris', name: 'Nilgiris', spot_count: 1 },
      ]);

      const districts = await service.getDistricts('TN');
      expect(districts).toHaveLength(1);
      expect(districts[0].id).toBe('tn-nilgiris');
      expect(mockPlacesProvider.getDistricts).toHaveBeenCalledWith('TN');
    });

    it('should delegate getPlacesByDistrict to places provider', async () => {
      mockPlacesProvider.getPlacesByDistrict = jest.fn().mockResolvedValue([
        { id: 'tn-002', name: 'Ooty', district_id: 'tn-nilgiris' },
      ]);

      const places = await service.getPlacesByDistrict('tn-nilgiris');
      expect(places).toHaveLength(1);
      expect(places[0].id).toBe('tn-002');
      expect(mockPlacesProvider.getPlacesByDistrict).toHaveBeenCalledWith('tn-nilgiris', undefined);
    });

    it('should delegate getPlacesByDistrict with category to places provider', async () => {
      mockPlacesProvider.getPlacesByDistrict = jest.fn().mockResolvedValue([
        { id: 'tn-005', name: 'Marina Beach', category: 'beach', district_id: 'tn-chennai' },
      ]);

      const places = await service.getPlacesByDistrict('tn-chennai', 'beach');
      expect(places).toHaveLength(1);
      expect(places[0].category).toBe('beach');
      expect(mockPlacesProvider.getPlacesByDistrict).toHaveBeenCalledWith('tn-chennai', 'beach');
    });
  });
});

