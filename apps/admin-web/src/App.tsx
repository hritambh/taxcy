import { lazy, Suspense } from 'react';
import { useTranslation } from 'react-i18next';
import { Route, Routes } from 'react-router';
import { useAuth } from './auth/context.js';
import { LoginPage } from './auth/LoginPage.js';
import { CreateOrgPage, NotStaffPage } from './auth/OnboardingPages.js';
import { Layout } from './components/Layout.js';
import { EmptyState, Spinner } from './components/ui.js';
import { AlertsPage } from './pages/AlertsPage.js';
import { DashboardPage } from './pages/DashboardPage.js';
import { DocumentsPage } from './pages/DocumentsPage.js';
import { DriversPage } from './pages/DriversPage.js';
import { ReviewPage } from './pages/ReviewPage.js';
import { SettingsPage } from './pages/SettingsPage.js';
import { SettlementsPage } from './pages/SettlementsPage.js';

// Pages that pull in MapLibre or Recharts load on demand, so the first paint doesn't wait on them.
const TripsPage = lazy(async () => ({ default: (await import('./pages/TripsPage.js')).TripsPage }));
const TripDetailPage = lazy(async () => ({
  default: (await import('./pages/TripDetailPage.js')).TripDetailPage,
}));
const VehiclesPage = lazy(async () => ({
  default: (await import('./pages/VehiclesPage.js')).VehiclesPage,
}));
const VehicleDetailPage = lazy(async () => ({
  default: (await import('./pages/VehicleDetailPage.js')).VehicleDetailPage,
}));
const FuelIndexPage = lazy(async () => ({
  default: (await import('./pages/FuelPages.js')).FuelIndexPage,
}));
const VehicleFuelPage = lazy(async () => ({
  default: (await import('./pages/FuelPages.js')).VehicleFuelPage,
}));

export function App() {
  const { t } = useTranslation();
  const auth = useAuth();
  if (auth.status === 'restoring') return <Spinner label={t('common.signingIn')} />;
  if (auth.status === 'signed_out') return <LoginPage />;
  if (!auth.session?.activeOrgId) return <CreateOrgPage />;
  if (!auth.isStaff) return <NotStaffPage />;

  return (
    <Suspense fallback={<Spinner />}>
      <Routes>
        <Route element={<Layout />}>
          <Route index element={<DashboardPage />} />
          <Route path="trips" element={<TripsPage />} />
          <Route path="trips/:id" element={<TripDetailPage />} />
          <Route path="vehicles" element={<VehiclesPage />} />
          <Route path="vehicles/:id" element={<VehicleDetailPage />} />
          <Route path="drivers" element={<DriversPage />} />
          <Route path="documents" element={<DocumentsPage />} />
          <Route path="fuel" element={<FuelIndexPage />} />
          <Route path="fuel/:vehicleId" element={<VehicleFuelPage />} />
          <Route path="alerts" element={<AlertsPage />} />
          <Route path="review" element={<ReviewPage />} />
          <Route path="settlements" element={<SettlementsPage />} />
          <Route path="settings" element={<SettingsPage />} />
          <Route
            path="*"
            element={
              <EmptyState title={t('app.pageNotFound')}>{t('app.pageNotFoundHint')}</EmptyState>
            }
          />
        </Route>
      </Routes>
    </Suspense>
  );
}
