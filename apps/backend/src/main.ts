import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Serve static assets from public directory (Safar Web Client)
  app.useStaticAssets(join(__dirname, '..', 'public'));

  // Global API versioned prefix — health check excluded
  app.setGlobalPrefix('api/v1', {
    exclude: ['health'],
  });

  // Global validation pipe — strips unknown fields, transforms types
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: false,
      transform: true,
    }),
  );

  // Global exception filter — consistent error response shape
  app.useGlobalFilters(new HttpExceptionFilter());

  // Global response interceptor — standard envelope { success, data, timestamp }
  app.useGlobalInterceptors(new TransformInterceptor());

  // CORS — restrict in production via config
  app.enableCors();

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  logger.log(`Safar Web App & API running on http://localhost:${port}`);
  logger.log(`Provider mode: ${process.env.PROVIDER_MODE ?? 'mock'}`);
}

bootstrap();
