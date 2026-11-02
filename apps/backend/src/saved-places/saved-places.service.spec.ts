import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { SavedPlacesService } from './saved-places.service';
import { SavedPlace } from './entities/saved-place.entity';

describe('SavedPlacesService', () => {
  let service: SavedPlacesService;
  let mockSavedRepo: any;

  beforeEach(async () => {
    mockSavedRepo = {
      find: jest.fn(),
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
      delete: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SavedPlacesService,
        {
          provide: getRepositoryToken(SavedPlace),
          useValue: mockSavedRepo,
        },
      ],
    }).compile();

    service = module.get<SavedPlacesService>(SavedPlacesService);
  });

  describe('getAll()', () => {
    it('should return list of saved place IDs from database', async () => {
      mockSavedRepo.find.mockResolvedValue([
        { placeId: 'tn-001', createdAt: new Date() },
        { placeId: 'ka-002', createdAt: new Date() },
      ]);

      const places = await service.getAll('user-123');
      expect(places).toEqual(['tn-001', 'ka-002']);
      expect(mockSavedRepo.find).toHaveBeenCalledWith({
        where: { userId: 'user-123' },
        order: { createdAt: 'DESC' },
      });
    });

    it('should fallback to in-memory store if DB query fails', async () => {
      mockSavedRepo.find.mockRejectedValue(new Error('DB connection failed'));

      const places = await service.getAll('user-123');
      expect(Array.isArray(places)).toBe(true);
    });
  });

  describe('save()', () => {
    it('should persist a new saved place entity', async () => {
      mockSavedRepo.findOne.mockResolvedValue(null);
      mockSavedRepo.create.mockReturnValue({ userId: 'user-123', placeId: 'tn-001' });
      mockSavedRepo.save.mockResolvedValue({ id: 'saved-uuid', userId: 'user-123', placeId: 'tn-001' });

      const result = await service.save('user-123', 'tn-001');
      expect(result).toEqual({ saved: true, place_id: 'tn-001' });
      expect(mockSavedRepo.save).toHaveBeenCalled();
    });

    it('should not duplicate save if already exists in database', async () => {
      mockSavedRepo.findOne.mockResolvedValue({ id: 'saved-uuid', userId: 'user-123', placeId: 'tn-001' });

      const result = await service.save('user-123', 'tn-001');
      expect(result).toEqual({ saved: true, place_id: 'tn-001' });
      expect(mockSavedRepo.save).not.toHaveBeenCalled();
    });
  });

  describe('remove()', () => {
    it('should delete saved place entity from database', async () => {
      mockSavedRepo.delete.mockResolvedValue({ affected: 1 });

      const result = await service.remove('user-123', 'tn-001');
      expect(result).toEqual({ removed: true, place_id: 'tn-001' });
      expect(mockSavedRepo.delete).toHaveBeenCalledWith({
        userId: 'user-123',
        placeId: 'tn-001',
      });
    });
  });
});
