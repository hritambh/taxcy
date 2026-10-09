import { z } from 'zod';

export const MembershipRole = z.enum(['owner', 'manager', 'driver']);
export type MembershipRole = z.infer<typeof MembershipRole>;

export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';

/**
 * Who may call a route.
 * - public: no token.
 * - user: any signed-in user, no org required (e.g. listing your own orgs).
 * - roles: signed in with an active org and at least one of these roles in it.
 */
export type Access =
  | { readonly kind: 'public' }
  | { readonly kind: 'user' }
  | { readonly kind: 'roles'; readonly roles: readonly MembershipRole[] };

export const access = {
  public: { kind: 'public' },
  user: { kind: 'user' },
  roles: (...roles: MembershipRole[]): Access => ({ kind: 'roles', roles }),
  staff: { kind: 'roles', roles: ['owner', 'manager'] },
  anyMember: { kind: 'roles', roles: ['owner', 'manager', 'driver'] },
} as const satisfies Record<string, Access | ((...r: MembershipRole[]) => Access)>;

export interface RouteDef {
  readonly method: HttpMethod;
  /** OpenAPI-style path, e.g. /trips/{id}/start. */
  readonly path: string;
  readonly summary: string;
  readonly tag: string;
  readonly access: Access;
  readonly params?: z.ZodType;
  readonly query?: z.ZodType;
  readonly body?: z.ZodType;
  readonly response: z.ZodType;
  /** Success status; defaults to 200 (204 means no body). */
  readonly status?: 200 | 201 | 202 | 204;
  /** Commands that require an Idempotency-Key header (replays return the stored response). */
  readonly idempotencyKey?: boolean;
}

export function defineRoute<const R extends RouteDef>(route: R): R {
  return route;
}

type Infer<S> = S extends z.ZodType ? z.output<S> : undefined;

/** The parsed input a handler receives for a route. */
export interface RouteInput<R extends RouteDef> {
  params: Infer<R['params']>;
  query: Infer<R['query']>;
  body: Infer<R['body']>;
}

/** What a handler returns for a route: the decoded (in-code) side, encoded to the wire on the way out. */
export type RouteOutput<R extends RouteDef> = z.output<R['response']>;

/** `/trips/{id}` → `/trips/:id` for Express/Nest. */
export function toExpressPath(path: string): string {
  return path.replace(/\{(\w+)\}/g, ':$1');
}
