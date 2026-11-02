import { Module } from '@nestjs/common';
import { TypeOrmModule, getRepositoryToken } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './strategies/jwt.strategy';
import { User } from './entities/user.entity';

const isDbActive = process.env.DB_ENABLED === 'true';

@Module({
  imports: [
    ...(isDbActive ? [TypeOrmModule.forFeature([User])] : []),
    PassportModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET'),
        signOptions: { expiresIn: config.get<string>('JWT_EXPIRY', '15m') },
      }),
    }),
  ],
  providers: [
    AuthService,
    JwtStrategy,
    ...(!isDbActive
      ? [
          {
            provide: getRepositoryToken(User),
            useValue: {
              findOne: () => Promise.resolve(null),
              find: () => Promise.resolve([]),
              create: (d: any) => d,
              save: (d: any) => Promise.resolve(d),
            },
          },
        ]
      : []),
  ],
  controllers: [AuthController],
  exports: [AuthService],
})
export class AuthModule {}
