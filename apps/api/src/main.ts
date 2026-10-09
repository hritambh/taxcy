import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';

// Typed config, pino logging and Sentry replace the raw env read and default logger in M0.2.
const app = await NestFactory.create(AppModule);
app.enableShutdownHooks();
await app.listen(Number(process.env['PORT'] ?? 3000));
