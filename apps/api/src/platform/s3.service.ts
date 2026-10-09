import { HeadBucketCommand, S3Client } from '@aws-sdk/client-s3';
import { Inject, Injectable } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from './config.js';

@Injectable()
export class S3Service {
  readonly client: S3Client;
  /** Client whose signed URLs use the host devices can reach (S3_PUBLIC_ENDPOINT). */
  readonly publicClient: S3Client;
  readonly bucket: string;

  constructor(@Inject(APP_CONFIG) config: AppConfig) {
    const base = {
      region: config.S3_REGION,
      forcePathStyle: true,
      credentials: {
        accessKeyId: config.S3_ACCESS_KEY_ID,
        secretAccessKey: config.S3_SECRET_ACCESS_KEY,
      },
    };
    this.client = new S3Client({ ...base, endpoint: config.S3_ENDPOINT });
    this.publicClient = new S3Client({
      ...base,
      endpoint: config.S3_PUBLIC_ENDPOINT ?? config.S3_ENDPOINT,
    });
    this.bucket = config.S3_BUCKET;
  }

  async ping(): Promise<void> {
    await this.client.send(new HeadBucketCommand({ Bucket: this.bucket }));
  }
}
