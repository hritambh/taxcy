import { cn } from '@taxcy/ui';
import {
  AlertTriangle,
  Banknote,
  Car,
  ClipboardCheck,
  FileText,
  Fuel,
  LayoutDashboard,
  LogOut,
  Menu,
  Route as RouteIcon,
  Settings,
  UserRound,
  Users,
  X,
  type LucideIcon,
} from 'lucide-react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { NavLink, Outlet } from 'react-router';
import { useAuth } from '../auth/context.js';
import { useAlertSummary } from '../lib/queries.js';
import { LanguageSwitcher } from './LanguageSwitcher.js';
import { Button, Select } from './ui.js';

interface NavItem {
  to: string;
  label:
    | 'dashboard'
    | 'trips'
    | 'vehicles'
    | 'drivers'
    | 'documents'
    | 'fuel'
    | 'alerts'
    | 'review'
    | 'settlements'
    | 'settings';
  icon: LucideIcon;
  badge?: 'alerts' | 'review';
}

const NAV: NavItem[] = [
  { to: '/', label: 'dashboard', icon: LayoutDashboard },
  { to: '/trips', label: 'trips', icon: RouteIcon },
  { to: '/vehicles', label: 'vehicles', icon: Car },
  { to: '/drivers', label: 'drivers', icon: Users },
  { to: '/documents', label: 'documents', icon: FileText },
  { to: '/fuel', label: 'fuel', icon: Fuel },
  { to: '/alerts', label: 'alerts', icon: AlertTriangle, badge: 'alerts' },
  { to: '/review', label: 'review', icon: ClipboardCheck, badge: 'review' },
  { to: '/settlements', label: 'settlements', icon: Banknote },
  { to: '/settings', label: 'settings', icon: Settings },
];

function CountBadge({ count, urgent }: { count: number; urgent: boolean }) {
  const { t } = useTranslation();
  if (!count) return null;
  return (
    <span
      className={cn(
        'ml-auto min-w-5 rounded-full px-1.5 py-0.5 text-center text-xs font-semibold tabular-nums',
        urgent ? 'bg-red-500 text-white' : 'bg-white/15 text-white',
      )}
      aria-label={t('nav.openCount', { count })}
    >
      {count > 99 ? '99+' : count}
    </span>
  );
}

function Sidebar({ onNavigate }: { onNavigate?: () => void }) {
  const { t } = useTranslation();
  const auth = useAuth();
  const summary = useAlertSummary();
  const openAlerts = summary.data
    ? summary.data.openAlerts.critical +
      summary.data.openAlerts.warning +
      summary.data.openAlerts.info
    : 0;
  const memberships = auth.session?.memberships ?? [];
  return (
    <div className="flex h-full flex-col text-brand-50">
      <div className="flex items-center gap-2.5 px-4 py-5">
        <span className="flex size-8 items-center justify-center rounded-lg bg-white text-brand-700 shadow-sm">
          <Car className="size-4.5" aria-hidden />
        </span>
        <span className="text-lg font-semibold tracking-tight text-white">{t('app.name')}</span>
      </div>
      <div className="px-3 pb-3">
        {memberships.length > 1 ? (
          <Select
            aria-label={t('nav.organization')}
            className="border-white/20 bg-white/10 text-white [&>option]:text-slate-900"
            value={auth.session?.activeOrgId ?? ''}
            onChange={(e) => void auth.switchOrg(e.target.value)}
          >
            {memberships.map((m) => (
              <option key={m.orgId} value={m.orgId}>
                {m.orgName}
              </option>
            ))}
          </Select>
        ) : (
          <p className="truncate rounded-md bg-white/10 px-2.5 py-1.5 text-sm font-medium text-white">
            {auth.activeMembership?.orgName}
          </p>
        )}
      </div>
      <nav aria-label={t('nav.main')} className="flex-1 space-y-0.5 overflow-y-auto px-2">
        {NAV.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === '/'}
            onClick={onNavigate}
            className={({ isActive }) =>
              cn(
                'flex items-center gap-2.5 rounded-md px-2.5 py-2 text-sm font-medium transition-colors focus-visible:outline-2 focus-visible:outline-white',
                isActive
                  ? 'bg-white text-brand-800 shadow-sm'
                  : 'text-brand-100 hover:bg-white/10 hover:text-white',
              )
            }
          >
            <item.icon className="size-4 shrink-0" aria-hidden />
            {t(`nav.${item.label}`)}
            {item.badge === 'alerts' && (
              <CountBadge
                count={openAlerts}
                urgent={(summary.data?.openAlerts.critical ?? 0) > 0}
              />
            )}
            {item.badge === 'review' && (
              <CountBadge count={summary.data?.openReviewItems ?? 0} urgent={false} />
            )}
          </NavLink>
        ))}
      </nav>
      <div className="border-t border-white/15 p-3">
        <p className="truncate text-sm font-medium text-white">
          {auth.session?.user.name ?? auth.session?.user.phone}
        </p>
        <p className="mb-2 text-xs text-brand-200">
          {auth.activeMembership?.roles.map((role) => t(`enums.role.${role}`)).join(', ')}
        </p>
        <LanguageSwitcher className="mb-2 text-brand-100" />
        <NavLink
          to="/account"
          onClick={onNavigate}
          className={({ isActive }) =>
            cn(
              'mb-1 flex h-8 items-center gap-1.5 rounded-md px-2.5 text-sm font-medium transition-colors focus-visible:outline-2 focus-visible:outline-white',
              isActive
                ? 'bg-white text-brand-800'
                : 'text-brand-100 hover:bg-white/10 hover:text-white',
            )
          }
        >
          <UserRound className="size-4" aria-hidden />
          {t('nav.myAccount')}
        </NavLink>
        <Button
          variant="ghost"
          size="sm"
          className="w-full justify-start text-brand-100 hover:bg-white/10 hover:text-white"
          onClick={() => void auth.logout()}
        >
          <LogOut className="size-4" aria-hidden />
          {t('nav.signOut')}
        </Button>
      </div>
    </div>
  );
}

export function Layout() {
  const { t } = useTranslation();
  const [menuOpen, setMenuOpen] = useState(false);
  return (
    <div className="min-h-screen lg:flex">
      <aside className="sticky top-0 hidden h-screen w-60 shrink-0 bg-gradient-to-b from-brand-800 to-brand-950 lg:block">
        <Sidebar />
      </aside>
      <header className="sticky top-0 z-20 flex items-center gap-2 bg-brand-800 px-4 py-2 text-white shadow-md lg:hidden">
        <Button
          variant="ghost"
          size="sm"
          className="text-white hover:bg-white/10"
          aria-label={t('nav.openMenu')}
          aria-expanded={menuOpen}
          onClick={() => {
            setMenuOpen(true);
          }}
        >
          <Menu className="size-5" aria-hidden />
        </Button>
        <span className="font-semibold">{t('app.name')}</span>
      </header>
      {menuOpen && (
        <div className="fixed inset-0 z-30 lg:hidden">
          <button
            type="button"
            aria-label={t('nav.closeMenu')}
            className="absolute inset-0 bg-brand-950/50"
            onClick={() => {
              setMenuOpen(false);
            }}
          />
          <aside className="absolute inset-y-0 left-0 w-64 bg-gradient-to-b from-brand-800 to-brand-950 shadow-xl">
            <Button
              variant="ghost"
              size="sm"
              aria-label={t('nav.closeMenu')}
              className="absolute top-4 right-2 text-white hover:bg-white/10"
              onClick={() => {
                setMenuOpen(false);
              }}
            >
              <X className="size-4" aria-hidden />
            </Button>
            <Sidebar
              onNavigate={() => {
                setMenuOpen(false);
              }}
            />
          </aside>
        </div>
      )}
      <main className="min-w-0 flex-1 px-4 py-6 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-6xl">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
