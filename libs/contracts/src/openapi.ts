import { z } from 'zod';
import { ErrorBody } from './errors.js';
import type { RouteDef } from './http.js';

type JsonSchema = Record<string, unknown>;

function toSchema(schema: z.ZodType, io: 'input' | 'output'): JsonSchema {
  return z.toJSONSchema(schema, {
    target: 'draft-2020-12',
    io,
    unrepresentable: 'any',
  });
}

function parametersFor(schema: z.ZodType | undefined, location: 'path' | 'query'): unknown[] {
  if (!schema) return [];
  const json = toSchema(schema, 'input');
  const properties = (json['properties'] ?? {}) as Record<string, JsonSchema>;
  const required = new Set((json['required'] ?? []) as string[]);
  return Object.entries(properties).map(([name, propSchema]) => ({
    name,
    in: location,
    required: location === 'path' || required.has(name),
    schema: propSchema,
  }));
}

const errorResponse = {
  description: 'Error',
  content: { 'application/json': { schema: toSchema(ErrorBody, 'output') } },
};

/** Builds an OpenAPI 3.1 document from route contracts. */
export function buildOpenApiDocument(
  routes: readonly RouteDef[],
  info: { title: string; version: string },
): JsonSchema {
  const paths: Record<string, Record<string, unknown>> = {};
  for (const route of routes) {
    const status = String(route.status ?? 200);
    const parameters = [
      ...parametersFor(route.params, 'path'),
      ...parametersFor(route.query, 'query'),
      ...(route.idempotencyKey
        ? [
            {
              name: 'Idempotency-Key',
              in: 'header',
              required: true,
              schema: { type: 'string', format: 'uuid' },
            },
          ]
        : []),
    ];
    const operation: Record<string, unknown> = {
      operationId: `${route.method.toLowerCase()}${route.path
        .replace(/[{}]/g, '')
        .replace(/\/(\w)/g, (_m, c: string) => c.toUpperCase())
        .replace(/[^A-Za-z0-9]/g, '')}`,
      summary: route.summary,
      tags: [route.tag],
      ...(route.access.kind === 'public' ? { security: [] } : {}),
      ...(parameters.length ? { parameters } : {}),
      ...(route.body
        ? {
            requestBody: {
              required: true,
              content: { 'application/json': { schema: toSchema(route.body, 'input') } },
            },
          }
        : {}),
      responses: {
        [status]:
          status === '204'
            ? { description: 'No content' }
            : {
                description: 'OK',
                content: { 'application/json': { schema: toSchema(route.response, 'output') } },
              },
        default: errorResponse,
      },
    };
    (paths[route.path] ??= {})[route.method.toLowerCase()] = operation;
  }
  return {
    openapi: '3.1.0',
    info,
    servers: [{ url: '/v1' }],
    components: {
      securitySchemes: { bearer: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' } },
    },
    security: [{ bearer: [] }],
    paths,
  };
}
