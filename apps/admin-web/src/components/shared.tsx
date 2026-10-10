import { ImageOff } from 'lucide-react';
import type { SelectHTMLAttributes } from 'react';
import { useTranslation } from 'react-i18next';
import { fmtRegistration } from '../lib/format.js';
import { useDrivers, useMediaUrl, useVehicles } from '../lib/queries.js';
import { Select, Spinner } from './ui.js';

type SelectProps = Omit<SelectHTMLAttributes<HTMLSelectElement>, 'onChange' | 'value'> & {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
};

export function VehicleSelect({ value, onChange, placeholder, ...props }: SelectProps) {
  const { t } = useTranslation();
  const vehicles = useVehicles('active');
  return (
    <Select
      {...props}
      value={value}
      onChange={(e) => {
        onChange(e.target.value);
      }}
      disabled={vehicles.isPending || props.disabled}
    >
      <option value="">
        {vehicles.isPending ? t('common.loading') : (placeholder ?? t('common.selectVehicle'))}
      </option>
      {vehicles.data?.map((v) => (
        <option key={v.id} value={v.id}>
          {fmtRegistration(v.registrationNo)} · {v.model}
        </option>
      ))}
    </Select>
  );
}

export function DriverSelect({ value, onChange, placeholder, ...props }: SelectProps) {
  const { t } = useTranslation();
  const drivers = useDrivers('active');
  return (
    <Select
      {...props}
      value={value}
      onChange={(e) => {
        onChange(e.target.value);
      }}
      disabled={drivers.isPending || props.disabled}
    >
      <option value="">
        {drivers.isPending ? t('common.loading') : (placeholder ?? t('common.selectDriver'))}
      </option>
      {drivers.data?.map((d) => (
        <option key={d.id} value={d.id}>
          {d.membershipStatus === 'invited' ? t('common.invitedSuffix', { name: d.name }) : d.name}
        </option>
      ))}
    </Select>
  );
}

/** A captured photo (odometer, receipt) loaded through a short-lived signed URL. */
export function Photo({
  mediaId,
  alt,
  className,
}: {
  mediaId: string | null | undefined;
  alt: string;
  className?: string;
}) {
  const { t } = useTranslation();
  const url = useMediaUrl(mediaId);
  if (!mediaId) return null;
  if (url.isPending) return <Spinner label={t('common.loadingPhoto')} />;
  if (url.isError) {
    return (
      <div className="flex items-center gap-2 rounded-md border border-dashed border-slate-300 p-4 text-xs text-slate-500">
        <ImageOff className="size-4" aria-hidden />
        {t('common.photoMissing')}
      </div>
    );
  }
  return (
    <a href={url.data.url} target="_blank" rel="noreferrer" className="block">
      <img
        src={url.data.url}
        alt={alt}
        className={className ?? 'max-h-48 rounded-md border border-slate-200 object-contain'}
      />
    </a>
  );
}
