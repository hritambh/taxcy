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
  Users,
  X,
  type LucideIcon,
} from 'lucide-react';
import { useState } from 'react';
import { NavLink, Outlet } from 'react-router';
import { useAuth } from '../auth/context.js';
import { useAlertSummary } from '../lib/queries.js';
import { Button, Select } from './ui.js';

interface NavItem {
  to: string;
  label: string;
  icon: LucideIcon;
  badge?: 'alerts' | 'review';
}

const NAV: NavItem[] = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/trips', label: 'Trips', icon: RouteIcon },
  { to: '/vehicles', label: 'Vehicles', icon: Car },
  { to: '/drivers', label: 'Drivers', icon: Users },
  { to: '/documents', label: 'Documents', icon: FileText },
  { to: '/fuel', label: 'Fuel', icon: Fuel },
  { to: '/alerts', label: 'Alerts', icon: AlertTriangle, badge: 'alerts' },
  { to: '/review', label: 'Review', icon: ClipboardCheck, badge: 'review' },
  { to: '/settlements', label: 'Settlements', icon: Banknote },
  { to: '/settings', label: 'Settings', icon: Settings },
];

function CountBadge({ count, urgent }: { count: number; urgent: boolean }) {
  if (!count) return null;
  return (
    <span
      className={cn(
        'ml-auto min-w-5 rounded-full px-1.5 py-0.5 text-center text-xs font-semibold tabular-nums',
        urgent ? 'bg-red-600 text-white' : 'bg-slate-200 text-slate-700',
      )}
      aria-label={`${String(count)} open`}
    >
      {count > 99 ? '99+' : count}
    </span>
  );
}

function Sidebar({ onNavigate }: { onNavigate?: () => void }) {
  const auth = useAuth();
  const summary = useAlertSummary();
  const openAlerts = summary.data
    ? summary.data.openAlerts.critical +
      summary.data.openAlerts.warning +
      summary.data.openAlerts.info
    : 0;
  const memberships = auth.session?.memberships ?? [];
  return (
    <div className="flex h-full flex-col">
      <div className="flex items-center gap-2 px-4 py-4 text-brand-700">
        <Car className="size-5" aria-hidden />
        <span className="font-semibold">Taxcy</span>
      </div>
      <div className="px-3 pb-3">
        {memberships.length > 1 ? (
          <Select
            aria-label="Organization"
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
          <p className="truncate px-1 text-sm font-medium text-slate-800">
            {auth.activeMembership?.orgName}
          </p>
        )}
      </div>
      <nav aria-label="Main" className="flex-1 space-y-0.5 overflow-y-auto px-2">
        {NAV.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === '/'}
            onClick={onNavigate}
            className={({ isActive }) =>
              cn(
                'flex items-center gap-2.5 rounded-md px-2.5 py-2 text-sm font-medium focus-visible:outline-2 focus-visible:outline-brand-500',
                isActive ? 'bg-brand-50 text-brand-700' : 'text-slate-700 hover:bg-slate-100',
              )
            }
          >
            <item.icon className="size-4 shrink-0" aria-hidden />
            {item.label}
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
      <div className="border-t border-slate-200 p-3">
        <p className="truncate text-sm font-medium text-slate-800">
          {auth.session?.user.name ?? auth.session?.user.phone}
        </p>
        <p className="mb-2 text-xs text-slate-500 capitalize">
          {auth.activeMembership?.roles.join(', ')}
        </p>
        <Button
          variant="ghost"
          size="sm"
          className="w-full justify-start"
          onClick={() => void auth.logout()}
        >
          <LogOut className="size-4" aria-hidden />
          Sign out
        </Button>
      </div>
    </div>
  );
}

export function Layout() {
  const [menuOpen, setMenuOpen] = useState(false);
  return (
    <div className="min-h-screen lg:flex">
      <aside className="sticky top-0 hidden h-screen w-60 shrink-0 border-r border-slate-200 bg-white lg:block">
        <Sidebar />
      </aside>
      <header className="sticky top-0 z-20 flex items-center gap-2 border-b border-slate-200 bg-white px-4 py-2 lg:hidden">
        <Button
          variant="ghost"
          size="sm"
          aria-label="Open menu"
          aria-expanded={menuOpen}
          onClick={() => {
            setMenuOpen(true);
          }}
        >
          <Menu className="size-5" aria-hidden />
        </Button>
        <span className="font-semibold text-brand-700">Taxcy</span>
      </header>
      {menuOpen && (
        <div className="fixed inset-0 z-30 lg:hidden">
          <button
            type="button"
            aria-label="Close menu"
            className="absolute inset-0 bg-slate-900/40"
            onClick={() => {
              setMenuOpen(false);
            }}
          />
          <aside className="absolute inset-y-0 left-0 w-64 bg-white shadow-xl">
            <Button
              variant="ghost"
              size="sm"
              aria-label="Close menu"
              className="absolute top-3 right-2"
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
