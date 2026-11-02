import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UnauthorizedException, ConflictException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { User } from './entities/user.entity';

describe('AuthService', () => {
  let service: AuthService;
  let mockUserRepo: any;
  let mockJwtService: any;
  let mockConfigService: any;

  beforeEach(async () => {
    mockUserRepo = {
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
    };

    mockJwtService = {
      sign: jest.fn().mockReturnValue('mock-jwt-token'),
    };

    mockConfigService = {
      get: jest.fn((key: string, defaultVal?: string) => {
        if (key === 'JWT_SECRET') return 'super-secret';
        if (key === 'JWT_EXPIRY') return '15m';
        if (key === 'JWT_REFRESH_EXPIRY') return '30d';
        return defaultVal;
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepo,
        },
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  describe('login()', () => {
    it('should login with dev fallback credentials', async () => {
      mockUserRepo.findOne.mockResolvedValue(null);

      const tokens = await service.login({
        email: 'dev@safar.app',
        password: 'safar123',
      });

      expect(tokens).toBeDefined();
      expect(tokens.accessToken).toBe('mock-jwt-token');
      expect(tokens.refreshToken).toBe('mock-jwt-token');
    });

    it('should throw UnauthorizedException on invalid credentials', async () => {
      mockUserRepo.findOne.mockResolvedValue(null);

      await expect(
        service.login({
          email: 'nonexistent@safar.app',
          password: 'wrongpassword',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('register()', () => {
    it('should register a new user and return tokens', async () => {
      mockUserRepo.findOne.mockResolvedValue(null);
      mockUserRepo.create.mockImplementation((dto: any) => ({
        id: 'new-user-uuid',
        ...dto,
      }));
      mockUserRepo.save.mockImplementation(async (user: any) => user);

      const tokens = await service.register('traveler@safar.app', 'securePassword123', 'Traveler');

      expect(tokens.accessToken).toBe('mock-jwt-token');
      expect(mockUserRepo.save).toHaveBeenCalled();
    });

    it('should throw ConflictException if user already exists', async () => {
      mockUserRepo.findOne.mockResolvedValue({ id: 'existing-id', email: 'traveler@safar.app' });

      await expect(
        service.register('traveler@safar.app', 'securePassword123'),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('refresh()', () => {
    it('should generate new tokens on refresh', async () => {
      const tokens = await service.refresh('user-id', 'traveler@safar.app');
      expect(tokens.accessToken).toBe('mock-jwt-token');
    });
  });
});
