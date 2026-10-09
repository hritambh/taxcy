import { Module } from '@nestjs/common';
import { EvidenceReconciler } from './evidence.reconciler.js';
import { MediaController } from './media.controller.js';
import { MediaRepository } from './media.repository.js';
import { MediaService } from './media.service.js';
import { OcrJob } from './ocr.job.js';
import { OCR_PROVIDER, StubOcrProvider } from './ocr.provider.js';

@Module({
  controllers: [MediaController],
  providers: [
    { provide: OCR_PROVIDER, useClass: StubOcrProvider },
    MediaRepository,
    MediaService,
    EvidenceReconciler,
    OcrJob,
  ],
  exports: [MediaRepository, EvidenceReconciler],
})
export class MediaModule {}
