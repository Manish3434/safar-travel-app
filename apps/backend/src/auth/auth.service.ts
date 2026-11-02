import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { LoginDto } from './dto/login.dto';
import { User } from './entities/user.entity';

@Injectable()
export class AuthService {
  // In-memory fallback for offline/isolated mock development
  private readonly devUsers = [
    {
      id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      email: 'dev@safar.app',
      name: 'Dev Traveler',
      passwordHash: '$2b$10$YvQ6C3z5e5YR5rIbXJ6P0.D9yFdHmP5G5QyLpFmCZkHxSbKD2mIqS',
    },
  ];

  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async login(dto: LoginDto) {
    let user: { id: string; email: string; passwordHash: string; name?: string } | null = null;

    try {
      user = await this.userRepo.findOne({ where: { email: dto.email } });
    } catch {
      // In case DB is not yet connected, fall back gracefully
    }

    if (!user) {
      user = this.devUsers.find((u) => u.email === dto.email) ?? null;
    }

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return this.generateTokens(user.id, user.email);
  }

  async register(email: string, passwordPlain: string, name?: string) {
    const existing = await this.userRepo.findOne({ where: { email } });
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const passwordHash = await bcrypt.hash(passwordPlain, 10);
    const newUser = this.userRepo.create({
      email,
      passwordHash,
      name,
    });

    const saved = await this.userRepo.save(newUser);
    return this.generateTokens(saved.id, saved.email);
  }

  async refresh(userId: string, email: string) {
    return this.generateTokens(userId, email);
  }

  private generateTokens(userId: string, email: string) {
    const payload = { sub: userId, email };
    const accessToken = this.jwt.sign(payload, {
      secret: this.config.get('JWT_SECRET'),
      expiresIn: this.config.get('JWT_EXPIRY', '15m'),
    });
    const refreshToken = this.jwt.sign(payload, {
      secret: this.config.get('JWT_SECRET'),
      expiresIn: this.config.get('JWT_REFRESH_EXPIRY', '30d'),
    });
    return { accessToken, refreshToken };
  }
}
