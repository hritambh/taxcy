import {
  Area,
  CartesianGrid,
  ComposedChart,
  Line,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
  type TooltipContentProps,
} from 'recharts';
import type { ChartPoint } from '../lib/fuel-chart.js';
import { fmtDayShort } from '../lib/format.js';

// Reference palette (dataviz skill): one series hue, status steps for verdicts,
// recessive chrome. The admin console is light-only, so only light steps are used.
const COLORS = {
  surface: '#fcfcfb',
  series: '#2a78d6',
  band: 'rgba(42, 120, 214, 0.10)',
  critical: '#d03b3b',
  serious: '#ec835a',
  grid: '#e1e0d9',
  axis: '#c3c2b7',
  muted: '#898781',
  ink: '#0b0b0b',
  secondary: '#52514e',
};

const fmtValue = (v: number, unitLabel: string) =>
  unitLabel === '₹/km' ? `₹${v.toFixed(2)}/km` : `${v.toFixed(1)} ${unitLabel}`;

function VerdictMarker({
  cx,
  cy,
  payload,
}: {
  cx?: number | undefined;
  cy?: number | undefined;
  payload?: ChartPoint | undefined;
}) {
  if (cx === undefined || cy === undefined || !payload) return null;
  if (payload.verdict === 'flagged') {
    return (
      <circle
        cx={cx}
        cy={cy}
        r={6}
        fill={COLORS.critical}
        stroke={COLORS.surface}
        strokeWidth={2}
      />
    );
  }
  if (payload.verdict === 'invalid') {
    const s = 6;
    return (
      <path
        d={`M${String(cx)},${String(cy - s)} L${String(cx + s)},${String(cy)} L${String(cx)},${String(cy + s)} L${String(cx - s)},${String(cy)} Z`}
        fill={COLORS.serious}
        stroke={COLORS.surface}
        strokeWidth={2}
      />
    );
  }
  return (
    <circle cx={cx} cy={cy} r={4} fill={COLORS.series} stroke={COLORS.surface} strokeWidth={2} />
  );
}

function ChartTooltip({
  active,
  payload,
  unitLabel,
}: {
  active: boolean | undefined;
  payload: readonly { payload?: unknown }[] | undefined;
  unitLabel: string;
}) {
  const point = payload?.[0]?.payload as ChartPoint | undefined;
  if (!active || !point) return null;
  const verdict =
    point.verdict === 'flagged'
      ? '⚠ Flagged'
      : point.verdict === 'invalid'
        ? '◆ Invalid (sent to review)'
        : 'Within normal range';
  return (
    <div className="rounded-md border border-slate-200 bg-white px-3 py-2 text-xs shadow-md">
      <p className="mb-1 font-medium" style={{ color: COLORS.secondary }}>
        Cycle ending {fmtDayShort(new Date(point.t).toISOString())} · {point.distanceKm} km
      </p>
      <p className="flex items-center gap-2">
        <span
          className="inline-block h-0.5 w-3"
          style={{ background: COLORS.series }}
          aria-hidden
        />
        <strong style={{ color: COLORS.ink }}>{fmtValue(point.value, unitLabel)}</strong>
      </p>
      {point.band && (
        <p style={{ color: COLORS.secondary }}>
          Normal range {fmtValue(point.band[0], unitLabel)} – {fmtValue(point.band[1], unitLabel)} (
          {point.method === 'sigma' ? 'kσ' : '% rule, new vehicle'})
        </p>
      )}
      <p style={{ color: COLORS.secondary }}>{verdict}</p>
    </div>
  );
}

/**
 * Efficiency (or ₹/km) per full-tank cycle over time, against the band each cycle was
 * judged against. Single series, so no legend box; a key explains band and markers.
 */
export function FuelChart({
  points,
  unitLabel,
  higherIsBetter,
}: {
  points: ChartPoint[];
  unitLabel: string;
  higherIsBetter: boolean;
}) {
  return (
    <figure>
      <figcaption className="mb-2 text-xs text-slate-500">
        {unitLabel} per full-tank cycle · {higherIsBetter ? 'higher is better' : 'lower is better'}
      </figcaption>
      <div className="h-72 rounded-md" style={{ background: COLORS.surface }}>
        <ResponsiveContainer width="100%" height="100%">
          <ComposedChart data={points} margin={{ top: 16, right: 16, bottom: 8, left: 0 }}>
            <CartesianGrid stroke={COLORS.grid} strokeWidth={1} vertical={false} />
            <XAxis
              dataKey="t"
              type="number"
              scale="time"
              domain={['dataMin', 'dataMax']}
              tickFormatter={(t: number) => fmtDayShort(new Date(t).toISOString())}
              stroke={COLORS.axis}
              tick={{ fill: COLORS.muted, fontSize: 12 }}
              tickLine={false}
            />
            <YAxis
              stroke={COLORS.axis}
              tick={{ fill: COLORS.muted, fontSize: 12 }}
              tickLine={false}
              axisLine={false}
              width={48}
              domain={['auto', 'auto']}
              tickFormatter={(v: number) =>
                unitLabel === '₹/km' ? `₹${v.toFixed(1)}` : v.toFixed(0)
              }
            />
            <Area
              dataKey="band"
              stroke="none"
              fill={COLORS.band}
              isAnimationActive={false}
              activeDot={false}
            />
            <Line
              dataKey="value"
              stroke={COLORS.series}
              strokeWidth={2}
              strokeLinejoin="round"
              strokeLinecap="round"
              dot={(props: { cx?: number; cy?: number; payload?: ChartPoint; index?: number }) => (
                <VerdictMarker
                  key={props.index}
                  cx={props.cx}
                  cy={props.cy}
                  payload={props.payload}
                />
              )}
              activeDot={{ r: 6, stroke: COLORS.surface, strokeWidth: 2, fill: COLORS.series }}
              isAnimationActive={false}
            />
            <Tooltip
              cursor={{ stroke: COLORS.axis, strokeWidth: 1 }}
              content={(props: TooltipContentProps) => (
                <ChartTooltip active={props.active} payload={props.payload} unitLabel={unitLabel} />
              )}
            />
          </ComposedChart>
        </ResponsiveContainer>
      </div>
      <ul
        className="mt-2 flex flex-wrap gap-4 text-xs"
        style={{ color: COLORS.secondary }}
        aria-label="Chart key"
      >
        <li className="flex items-center gap-1.5">
          <span
            className="inline-block h-0.5 w-4"
            style={{ background: COLORS.series }}
            aria-hidden
          />
          Cycle value
        </li>
        <li className="flex items-center gap-1.5">
          <span
            className="inline-block h-3 w-4 rounded-sm"
            style={{ background: COLORS.band }}
            aria-hidden
          />
          Normal range at the time
        </li>
        <li className="flex items-center gap-1.5">
          <span
            className="inline-block size-2.5 rounded-full"
            style={{ background: COLORS.critical }}
            aria-hidden
          />
          Flagged
        </li>
        <li className="flex items-center gap-1.5">
          <span
            className="inline-block size-2.5 rotate-45"
            style={{ background: COLORS.serious }}
            aria-hidden
          />
          Invalid (in review queue)
        </li>
      </ul>
    </figure>
  );
}
