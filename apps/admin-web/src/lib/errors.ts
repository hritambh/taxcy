import { ErrorBody } from '@taxcy/contracts';

/** An API failure carrying the server's error envelope (code + human message). */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly details?: unknown,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export function toApiError(status: number, body: unknown): ApiError {
  const parsed = ErrorBody.safeParse(body);
  if (parsed.success) {
    const { code, message, details } = parsed.data.error;
    return new ApiError(status, code, message, details);
  }
  return new ApiError(
    status,
    status >= 500 ? 'INTERNAL' : 'UNKNOWN',
    `Request failed (${String(status)})`,
  );
}

export function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return 'Something went wrong';
}
