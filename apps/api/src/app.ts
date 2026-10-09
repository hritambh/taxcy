import { NestFactory } from '@nestjs/core';
import type { INestApplication } from '@nestjs/common';
import { allRoutes, buildOpenApiDocument } from '@taxcy/contracts';
import type { Express } from 'express';
import { Logger } from 'nestjs-pino';
import { AppModule } from './app.module.js';
import { APP_CONFIG, type AppConfig } from './platform/config.js';
import { assertRoutesBound } from './platform/http/route-registry.js';

const DOCS_HTML = `<!doctype html>
<html><head><meta charset="utf-8"><title>Taxcy API</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css"></head>
<body><div id="ui"></div>
<script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
<script>SwaggerUIBundle({ url: '/v1/openapi.json', dom_id: '#ui' });</script>
</body></html>`;

export function openApiDocument(): Record<string, unknown> {
  return buildOpenApiDocument(allRoutes, { title: 'Taxcy API', version: '0.1.0' });
}

/** Builds the configured Nest app (shared by main.ts and integration tests). */
export async function createApp(options: { logs?: boolean } = {}): Promise<INestApplication> {
  const app = await NestFactory.create(
    AppModule,
    options.logs === false ? { logger: false } : { bufferLogs: true },
  );
  if (options.logs !== false) app.useLogger(app.get(Logger));
  const config = app.get<AppConfig>(APP_CONFIG);

  app.setGlobalPrefix('v1');
  app.enableCors({
    origin: config.CORS_ORIGINS,
    exposedHeaders: ['X-Request-Id', 'Idempotent-Replay'],
  });
  app.enableShutdownHooks();

  // Served outside Nest routing: these aren't API operations and need no contract.
  const express = app.getHttpAdapter().getInstance() as Express;
  const document = openApiDocument();
  express.get('/v1/openapi.json', (_req, res) => res.json(document));
  express.get('/docs', (_req, res) => res.type('html').send(DOCS_HTML));

  await app.init();
  assertRoutesBound(app, allRoutes);
  return app;
}
