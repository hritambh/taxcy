import { CreateBucketCommand, S3Client } from '@aws-sdk/client-s3';
import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import { RedisContainer, type StartedRedisContainer } from '@testcontainers/redis';
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { GenericContainer, Wait, type StartedTestContainer } from 'testcontainers';

const repoRoot = fileURLToPath(new URL('../../../', import.meta.url));

let postgres: StartedPostgreSqlContainer | undefined;
let redis: StartedRedisContainer | undefined;
let s3: StartedTestContainer | undefined;

/**
 * Starts throwaway PostGIS, Redis and RustFS containers, creates the database roles,
 * applies all migrations as the owner, and points the app (as taxcy_api, so RLS
 * applies) at them via environment variables inherited by the test workers.
 */
export async function setup(): Promise<void> {
  [postgres, redis, s3] = await Promise.all([
    new PostgreSqlContainer('imresamu/postgis:16-3.5')
      .withDatabase('taxcy')
      .withUsername('taxcy')
      .withPassword('taxcy')
      .start(),
    new RedisContainer('redis:8-alpine').start(),
    new GenericContainer('rustfs/rustfs:1.0.1')
      .withEnvironment({ RUSTFS_ACCESS_KEY: 'taxcy', RUSTFS_SECRET_KEY: 'taxcy-test-secret' })
      .withExposedPorts(9000)
      .withWaitStrategy(Wait.forHttp('/health', 9000))
      .start(),
  ]);

  await postgres.exec([
    'psql',
    '-U',
    'taxcy',
    '-d',
    'taxcy',
    '-c',
    readFileSync(`${repoRoot}infra/postgres/init-roles.sql`, 'utf8'),
  ]);

  const host = postgres.getHost();
  const port = postgres.getMappedPort(5432);
  const ownerUrl = `postgres://taxcy:taxcy@${host}:${port}/taxcy`;
  execFileSync('node', ['node_modules/.bin/prisma', 'migrate', 'deploy'], {
    cwd: `${repoRoot}libs/db`,
    env: { ...process.env, DATABASE_MIGRATION_URL: ownerUrl },
    stdio: 'pipe',
  });

  const s3Endpoint = `http://${s3.getHost()}:${s3.getMappedPort(9000)}`;
  const s3Client = new S3Client({
    endpoint: s3Endpoint,
    region: 'ap-south-1',
    forcePathStyle: true,
    credentials: { accessKeyId: 'taxcy', secretAccessKey: 'taxcy-test-secret' },
  });
  await s3Client.send(new CreateBucketCommand({ Bucket: 'taxcy-media' }));

  Object.assign(process.env, {
    NODE_ENV: 'test',
    LOG_LEVEL: 'silent',
    DATABASE_URL: `postgres://taxcy_api:taxcy_api@${host}:${port}/taxcy`,
    DATABASE_MIGRATION_URL: ownerUrl,
    REDIS_URL: redis.getConnectionUrl(),
    S3_ENDPOINT: s3Endpoint,
    S3_REGION: 'ap-south-1',
    S3_BUCKET: 'taxcy-media',
    S3_ACCESS_KEY_ID: 'taxcy',
    S3_SECRET_ACCESS_KEY: 'taxcy-test-secret',
    JWT_ACCESS_SECRET: 'integration-test-secret-0123456789abcdef',
  });
}

export async function teardown(): Promise<void> {
  await Promise.all([postgres?.stop(), redis?.stop(), s3?.stop()]);
}
