import { Injectable, Logger } from '@nestjs/common';

export interface SmsProvider {
  sendOtp(phone: string, code: string): Promise<void>;
}

export const SMS_PROVIDER = Symbol('SMS_PROVIDER');

/**
 * Development/test provider: logs the code instead of sending an SMS. It also keeps
 * the last code per phone in memory so integration tests can log in.
 */
@Injectable()
export class ConsoleSmsProvider implements SmsProvider {
  private readonly logger = new Logger('ConsoleSmsProvider');
  private readonly lastCodes = new Map<string, string>();

  sendOtp(phone: string, code: string): Promise<void> {
    this.lastCodes.set(phone, code);
    this.logger.log(`otp.issued phone=${phone} code=${code} (dev only, not sent)`);
    return Promise.resolve();
  }

  lastCodeFor(phone: string): string | undefined {
    return this.lastCodes.get(phone);
  }
}
