import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { api, call } from './api.js';
import type { Alert, ReviewItem, TripStatus } from './api-types.js';

/** Query keys, grouped so a mutation can invalidate a whole area. */
export const keys = {
  vehicles: ['vehicles'] as const,
  vehicle: (id: string) => ['vehicles', id] as const,
  vehicleModels: ['vehicle-models'] as const,
  drivers: ['drivers'] as const,
  driver: (id: string) => ['drivers', id] as const,
  documents: ['documents'] as const,
  trips: ['trips'] as const,
  trip: (id: string) => ['trips', id] as const,
  fuel: ['fuel'] as const,
  alerts: ['alerts'] as const,
  review: ['review-items'] as const,
  settlements: ['settlements'] as const,
  settings: ['settings'] as const,
  media: (id: string) => ['media', id] as const,
};

export function useVehicles(status?: 'active' | 'inactive') {
  return useQuery({
    queryKey: [...keys.vehicles, { status }],
    queryFn: () => call(api.GET('/vehicles', { params: { query: status ? { status } : {} } })),
  });
}

export function useVehicle(id: string) {
  return useQuery({
    queryKey: keys.vehicle(id),
    queryFn: () => call(api.GET('/vehicles/{id}', { params: { path: { id } } })),
  });
}

export function useVehicleModels() {
  return useQuery({
    queryKey: keys.vehicleModels,
    queryFn: () => call(api.GET('/vehicle-models')),
    staleTime: 3_600_000,
  });
}

export function useDrivers(status?: 'active' | 'inactive') {
  return useQuery({
    queryKey: [...keys.drivers, { status }],
    queryFn: () => call(api.GET('/drivers', { params: { query: status ? { status } : {} } })),
  });
}

export function useDriver(id: string) {
  return useQuery({
    queryKey: keys.driver(id),
    queryFn: () => call(api.GET('/drivers/{id}', { params: { path: { id } } })),
  });
}

export interface DocumentFilter {
  vehicleId?: string;
  driverId?: string;
  expiringWithinDays?: number;
}

export function useDocuments(filter: DocumentFilter = {}) {
  return useQuery({
    queryKey: [...keys.documents, filter],
    queryFn: () => call(api.GET('/documents', { params: { query: filter } })),
  });
}

export interface TripFilter {
  status?: TripStatus;
  driverId?: string;
  vehicleId?: string;
  from?: string;
  to?: string;
  limit?: number;
}

export function useTrips(filter: TripFilter = {}) {
  return useQuery({
    queryKey: [...keys.trips, 'list', filter],
    queryFn: () => call(api.GET('/trips', { params: { query: filter } })),
    placeholderData: keepPreviousData,
  });
}

export function useTrip(id: string) {
  return useQuery({
    queryKey: keys.trip(id),
    queryFn: () => call(api.GET('/trips/{id}', { params: { path: { id } } })),
  });
}

export function useTripEvents(id: string) {
  return useQuery({
    queryKey: [...keys.trip(id), 'events'],
    queryFn: () => call(api.GET('/trips/{id}/events', { params: { path: { id } } })),
  });
}

export function useTripRoute(id: string, enabled: boolean) {
  return useQuery({
    queryKey: [...keys.trip(id), 'route'],
    queryFn: () => call(api.GET('/trips/{id}/route', { params: { path: { id } } })),
    enabled,
  });
}

export function useDistanceCheck(id: string, enabled: boolean) {
  return useQuery({
    queryKey: [...keys.trip(id), 'distance-check'],
    queryFn: () => call(api.GET('/trips/{id}/distance-check', { params: { path: { id } } })),
    enabled,
  });
}

export function useFuelFills(filter: {
  vehicleId?: string;
  driverId?: string;
  includeVoided?: boolean;
  limit?: number;
}) {
  return useQuery({
    queryKey: [...keys.fuel, 'fills', filter],
    queryFn: () =>
      call(
        api.GET('/fuel-fills', {
          params: {
            query: {
              ...(filter.vehicleId ? { vehicleId: filter.vehicleId } : {}),
              ...(filter.driverId ? { driverId: filter.driverId } : {}),
              ...(filter.includeVoided ? { includeVoided: 'true' } : {}),
              limit: filter.limit ?? 200,
            },
          },
        }),
      ),
  });
}

export function useVehicleAudit(vehicleId: string) {
  return useQuery({
    queryKey: [...keys.fuel, 'audit', vehicleId],
    queryFn: () =>
      call(api.GET('/vehicles/{id}/fuel-cycles', { params: { path: { id: vehicleId } } })),
  });
}

export function useAlerts(filter: {
  status?: Alert['status'];
  kind?: Alert['kind'];
  vehicleId?: string;
  tripId?: string;
  limit?: number;
}) {
  return useQuery({
    queryKey: [...keys.alerts, 'list', filter],
    queryFn: () => call(api.GET('/alerts', { params: { query: filter } })),
    placeholderData: keepPreviousData,
  });
}

export function useAlertSummary() {
  return useQuery({
    queryKey: [...keys.alerts, 'summary'],
    queryFn: () => call(api.GET('/alerts/summary')),
    refetchInterval: 60_000,
  });
}

export function useReviewItems(status?: ReviewItem['status']) {
  return useQuery({
    queryKey: [...keys.review, { status }],
    queryFn: () => call(api.GET('/review-items', { params: { query: status ? { status } : {} } })),
  });
}

export function useSettlements(date: string) {
  return useQuery({
    queryKey: [...keys.settlements, date],
    queryFn: () => call(api.GET('/settlements', { params: { query: { date } } })),
  });
}

export function useSettlement(date: string, driverId: string | null) {
  return useQuery({
    queryKey: [...keys.settlements, date, driverId],
    queryFn: () =>
      call(
        api.GET('/settlements/{date}/drivers/{driverId}', {
          params: { path: { date, driverId: driverId ?? '' } },
        }),
      ),
    enabled: driverId !== null,
  });
}

export function useAuditSettings() {
  return useQuery({
    queryKey: [...keys.settings, 'audit'],
    queryFn: () => call(api.GET('/settings/audit')),
  });
}

export function useDefaultPayRule() {
  return useQuery({
    queryKey: [...keys.settings, 'driver-pay'],
    queryFn: () => call(api.GET('/settings/driver-pay')),
  });
}

/** A short-lived signed URL for a photo; refreshed before it expires. */
export function useMediaUrl(id: string | null | undefined) {
  return useQuery({
    queryKey: keys.media(id ?? ''),
    queryFn: () => call(api.GET('/media/{id}/url', { params: { path: { id: id ?? '' } } })),
    enabled: Boolean(id),
    staleTime: 240_000,
    retry: false,
  });
}
