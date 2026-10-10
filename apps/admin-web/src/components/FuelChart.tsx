import { useTranslation } from 'react-i18next';
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
import { intlLocale } from '../i18n/index.js';
import type { ChartPoint } from '../lib/fuel-chart.js';
import { fmtDayShort, fmtDecimal1, fmtInrExact, fmtKm, fmtNumber } from '../lib/format.js';

// Reference palette (dataviz skill): one series hue, status steps for verdicts,
// recessive blue-grey chrome to match the console theme. Light-only.
const COLORS = {
  surface: '#ffffff',
  series: '#2563eb',
  band: 'rgba(37, 99, 235, 0.10)',
  critical: '#d03b3b',
  serious: '#ec835a',
  grid: '#e3eaf6',
  axis: '#bccbe3',
  muted: '#637594',
  ink: '#121b2f',
  secondary: '#4a5a77',
};

/** What the chart plots: km per litre/kg, or running cost (points are in ₹/km). */
interface ChartUnit {
  metric: 'km_per_unit' | 'paise_per_km';
  unit: 'L' | 'kg';
}

interface ChartFormat {
  /** "km/L", "₹/km" in the user's language. */
  unitText: string;
  value: (v: number) => string;
  tick: (v: number) => string;
}

function useChartFormat({ metric, unit }: ChartUnit): ChartFormat {
  const { t } = useTranslation();
  if (metric === 'paise_per_km') {
    const tick = new Intl.NumberFormat(intlLocale(), {
      style: 'currency',
      currency: 'INR',
      minimumFractionDigits: 1,
      maximumFractionDigits: 1,
    });
    return {
      unitText: t('fleet.chart.unitPerKm'),
      value: (v) => t('units.perKm', { amount: fmtInrExact(Math.round(v * 100)) }),
      tick: (v) => tick.format(v),
    };
  }
  const unitName = t(`units.${unit}`);
  return {
    unitText: t('fleet.chart.unitKmPer', { unit: unitName }),
    value: (v) => t('units.kmPerUnit', { value: fmtDecimal1(v), unit: unitName }),
    tick: (v) => fmtNumber(v),
  };
}

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
  format,
}: {
  active: boolean | undefined;
  payload: readonly { payload?: unknown }[] | undefined;
  format: ChartFormat;
}) {
  const { t } = useTranslation();
  const point = payload?.[0]?.payload as ChartPoint | undefined;
  if (!active || !point) return null;
  const verdict =
    point.verdict === 'flagged'
      ? t('fleet.chart.flagged')
      : point.verdict === 'invalid'
        ? t('fleet.chart.invalid')
        : t('fleet.chart.withinRange');
  return (
    <div className="rounded-md border border-slate-200 bg-white px-3 py-2 text-xs shadow-md">
      <p className="mb-1 font-medium" style={{ color: COLORS.secondary }}>
        {t('fleet.chart.cycleEnding', {
          date: fmtDayShort(new Date(point.t).toISOString()),
          distance: fmtKm(point.distanceKm),
        })}
      </p>
      <p className="flex items-center gap-2">
        <span
          className="inline-block h-0.5 w-3"
          style={{ background: COLORS.series }}
          aria-hidden
        />
        <strong style={{ color: COLORS.ink }}>{format.value(point.value)}</strong>
      </p>
      {point.band && (
        <p style={{ color: COLORS.secondary }}>
          {t('fleet.chart.normalRange', {
            low: format.value(point.band[0]),
            high: format.value(point.band[1]),
            rule:
              point.method === 'sigma' ? t('fleet.chart.ruleSigma') : t('fleet.chart.rulePercent'),
          })}
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
  metric,
  unit,
  higherIsBetter,
}: ChartUnit & {
  points: ChartPoint[];
  higherIsBetter: boolean;
}) {
  const { t } = useTranslation();
  const format = useChartFormat({ metric, unit });
  return (
    <figure>
      <figcaption className="mb-2 text-xs text-slate-500">
        {t('fleet.chart.caption', {
          unit: format.unitText,
          direction: higherIsBetter
            ? t('fleet.chart.higherIsBetter')
            : t('fleet.chart.lowerIsBetter'),
        })}
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
              tickFormatter={format.tick}
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
                <ChartTooltip active={props.active} payload={props.payload} format={format} />
              )}
            />
          </ComposedChart>
        </ResponsiveContainer>
      </div>
      <ul
        className="mt-2 flex flex-wrap gap-4 text-xs"
        style={{ color: COLORS.secondary }}
        aria-label={t('fleet.chart.key')}
      >
        <li className="flex items-center gap-1.5">
          <span
            className="inline-block h-0.5 w-4"
            style={{ background: COLORS.series }}
            aria-hidden
          />
          {t('fleet.chart.keyValue')}
        </li>
        <li className="flex items-center gap-1.5">
          <span
            className="inline-block h-3 w-4 rounded-sm"
            style={{ background: COLORS.band }}
            aria-hidden
          />
          {t('fleet.chart.keyBand')}
        </li>
        <li className="flex items-center gap-1.5">
          <span
            className="inline-block size-2.5 rounded-full"
            style={{ background: COLORS.critical }}
            aria-hidden
          />
          {t('fleet.chart.keyFlagged')}
        </li>
        <li className="flex items-center gap-1.5">
          <span
            className="inline-block size-2.5 rotate-45"
            style={{ background: COLORS.serious }}
            aria-hidden
          />
          {t('fleet.chart.keyInvalid')}
        </li>
      </ul>
    </figure>
  );
}
