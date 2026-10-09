import { Injectable, Logger } from '@nestjs/common';
import { istBusinessDate } from '@taxcy/domain';
import { OnJob } from '../../platform/jobs/on-job.js';
import { Db } from '../../platform/prisma.service.js';
import { DocumentsService } from './documents.service.js';
import { SettingsService } from './settings.service.js';

/** Daily at 06:00 IST: raises 30/7/1-day and expired alerts for every org's documents. */
@Injectable()
export class DocumentExpiryJob {
  private readonly logger = new Logger('DocumentExpiryJob');

  constructor(
    private readonly db: Db,
    private readonly documents: DocumentsService,
    private readonly settings: SettingsService,
  ) {}

  @OnJob('fleet.document_expiry_scan')
  async run(): Promise<void> {
    const today = istBusinessDate(new Date());
    const orgs = await this.db.system((tx) => tx.organization.findMany({ select: { id: true } }));
    let evaluated = 0;
    for (const org of orgs) {
      evaluated += await this.db.tenant(org.id, async (tx) => {
        const { audit } = await this.settings.get(tx);
        const horizon = new Date(
          Date.parse(`${today}T00:00:00Z`) + Math.max(...audit.docAlertDays) * 86_400_000,
        );
        const docs = await tx.document.findMany({
          where: { orgId: org.id, supersededBy: null, expiresOn: { lte: horizon } },
        });
        for (const doc of docs) await this.documents.evaluateAlerts(tx, doc, today);
        return docs.length;
      });
    }
    this.logger.log(
      `document expiry scan: ${evaluated} documents across ${orgs.length} orgs (IST ${today})`,
    );
  }
}
