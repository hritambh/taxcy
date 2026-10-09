import { ImageOff } from 'lucide-react';
import type { SelectHTMLAttributes } from 'react';
import { fmtRegistration } from '../lib/format.js';
import { useDrivers, useMediaUrl, useVehicles } from '../lib/queries.js';
import { Select, Spinner } from './ui.js';

type SelectProps = Omit<SelectHTMLAttributes<HTMLSelectElement>, 'onChange' | 'value'> & {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
};

export function VehicleSelect({
  value,
  onChange,
  placeholder = 'Select a vehicle',
  ...props
}: SelectProps) {
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
      <option value="">{vehicles.isPending ? 'Loading…' : placeholder}</option>
      {vehicles.data?.map((v) => (
        <option key={v.id} value={v.id}>
          {fmtRegistration(v.registrationNo)} · {v.model}
        </option>
      ))}
    </Select>
  );
}

export function DriverSelect({
  value,
  onChange,
  placeholder = 'Select a driver',
  ...props
}: SelectProps) {
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
      <option value="">{drivers.isPending ? 'Loading…' : placeholder}</option>
      {drivers.data?.map((d) => (
        <option key={d.id} value={d.id}>
          {d.name}
          {d.membershipStatus === 'invited' ? ' (invited)' : ''}
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
  const url = useMediaUrl(mediaId);
  if (!mediaId) return null;
  if (url.isPending) return <Spinner label="Loading photo…" />;
  if (url.isError) {
    return (
      <div className="flex items-center gap-2 rounded-md border border-dashed border-slate-300 p-4 text-xs text-slate-500">
        <ImageOff className="size-4" aria-hidden />
        Photo not uploaded yet (the phone may still be offline).
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
