import {
  Injectable,
  type CallHandler,
  type ExecutionContext,
  type NestInterceptor,
} from '@nestjs/common';
import { map, type Observable } from 'rxjs';
import { contractOf } from './route.js';

/**
 * Encodes every response through its contract's response schema: codecs turn Dates
 * into ISO strings, unknown fields are stripped (nothing leaks by accident), and a
 * handler returning the wrong shape fails loudly as a 500 instead of silently
 * breaking clients.
 */
@Injectable()
export class ContractResponseInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const contract = contractOf(context);
    if (!contract || contract.status === 204) return next.handle();
    return next.handle().pipe(map((value: unknown) => contract.response.encode(value)));
  }
}
