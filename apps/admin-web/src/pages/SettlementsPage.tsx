import { useState } from 'react';
import {
  Badge,
  Button,
  Card,
  EmptyState,
  InlineError,
  Input,
  Modal,
  PageHeader,
  QueryState,
  Stat,
  Table,
  Td,
  Th,
} from '../components/ui.js';
import { api, call, idempotencyKey } from '../lib/api.js';
import type { SettlementLine, SettlementSummary } from '../lib/api-types.js';
import { fmtDate, fmtDateTime, fmtInr, humanize, istDaysAgo, istToday } from '../lib/format.js';
import { describePayRule, netPayableText } from '../lib/money.js';
import { useApiMutation } from '../lib/mutations.js';
import { keys, useSettlement, useSettlements } from '../lib/queries.js';

function NetPayable({ paise }: { paise: number }) {
  const { text, tone } = netPayableText(paise);
  const className =
    tone === 'owed'
      ? 'font-semibold text-amber-700'
      : tone === 'owes'
        ? 'font-semibold text-slate-900'
        : 'text-slate-500';
  return <span className={className}>{text}</span>;
}

export function SettlementRow({ s, onOpen }: { s: SettlementSummary; onOpen: () => void }) {
  return (
    <tr className="hover:bg-slate-50">
      <Td>
        <button
          type="button"
          onClick={onOpen}
          className="font-medium text-brand-700 hover:underline"
        >
          {s.driverName}
        </button>
        <span className="block text-xs text-slate-500">
          {s.tripCount === 1 ? '1 trip' : `${String(s.tripCount)} trips`}
        </span>
      </Td>
      <Td align="right">{fmtInr(s.expectedFarePaise)}</Td>
      <Td align="right">{fmtInr(s.cashPaise)}</Td>
      <Td align="right">{fmtInr(s.onlinePaise)}</Td>
      <Td align="right">{fmtInr(s.driverExpensesPaise)}</Td>
      <Td align="right">{fmtInr(s.driverEarningsPaise)}</Td>
      <Td align="right">{s.carriedAdjustmentPaise ? fmtInr(s.carriedAdjustmentPaise) : '—'}</Td>
      <Td align="right">
        <NetPayable paise={s.netPayablePaise} />
        {s.shortfallPaise !== 0 && (
          <span className="block text-xs text-red-700">Shortfall {fmtInr(s.shortfallPaise)}</span>
        )}
      </Td>
      <Td>
        {s.status === 'settled' ? (
          <Badge tone="success">Settled</Badge>
        ) : (
          <Badge tone="warning">Draft</Badge>
        )}
      </Td>
    </tr>
  );
}

const LINE_LABELS: Record<SettlementLine['refType'], string> = {
  trip: 'Trip',
  trip_charge: 'Charge',
  collection: 'Payment',
  fuel_fill: 'Fuel',
  adjustment: 'Late item',
};

function SettlementDrawer({
  date,
  driverId,
  onClose,
}: {
  date: string;
  driverId: string;
  onClose: () => void;
}) {
  const detail = useSettlement(date, driverId);
  const settle = useApiMutation(
    () =>
      call(
        api.POST('/settlements/{date}/drivers/{driverId}/settle', {
          params: { path: { date, driverId }, header: idempotencyKey() },
        }),
      ),
    [keys.settlements, keys.trips],
  );
  return (
    <Modal
      open
      wide
      onClose={onClose}
      title={detail.data ? `${detail.data.driverName} · ${fmtDate(date)}` : 'Settlement'}
    >
      <QueryState query={detail}>
        {(d) => (
          <div className="space-y-5">
            <dl className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              <Stat label="Expected fare" value={fmtInr(d.expectedFarePaise)} />
              <Stat label="Cash collected" value={fmtInr(d.cashPaise)} />
              <Stat label="Online (to you)" value={fmtInr(d.onlinePaise)} />
              <Stat label="Driver’s expenses" value={fmtInr(d.driverExpensesPaise)} />
              <Stat
                label="Driver’s earnings"
                value={fmtInr(d.driverEarningsPaise)}
                hint={describePayRule(d.payRule)}
              />
              <Stat
                label="Late items"
                value={d.carriedAdjustmentPaise ? fmtInr(d.carriedAdjustmentPaise) : '—'}
              />
              <Stat
                label="Shortfall"
                value={fmtInr(d.shortfallPaise)}
                hint="Expected fare minus everything collected"
              />
              <Stat label="Settlement" value={<NetPayable paise={d.netPayablePaise} />} />
            </dl>
            <p className="rounded-md bg-slate-50 p-3 text-xs text-slate-600">
              Net = cash collected − expenses the driver paid − driver’s earnings ± late items from
              already-settled days.
            </p>
            <Table>
              <thead>
                <tr>
                  <Th>Item</Th>
                  <Th>Details</Th>
                  <Th align="right">Amount</Th>
                </tr>
              </thead>
              <tbody>
                {d.lines.map((line) => (
                  <tr key={`${line.refType}:${line.refId}`}>
                    <Td>{LINE_LABELS[line.refType]}</Td>
                    <Td>
                      {line.description || humanize(line.refType)}
                      {line.originalDate && (
                        <span className="block text-xs text-amber-700">
                          From {fmtDate(line.originalDate)}, synced after that day was settled
                        </span>
                      )}
                    </Td>
                    <Td align="right">{fmtInr(line.amountPaise)}</Td>
                  </tr>
                ))}
              </tbody>
            </Table>
            <InlineError error={settle.error} />
            <div className="flex items-center justify-between gap-3">
              {d.status === 'settled' ? (
                <p className="text-sm text-slate-600">
                  Settled {fmtDateTime(d.settledAt)}. Later changes carry into the next day.
                </p>
              ) : (
                <p className="text-sm text-slate-600">
                  Mark settled once you’ve received the cash. This locks the day.
                </p>
              )}
              {d.status === 'draft' && (
                <Button
                  busy={settle.isPending}
                  disabled={d.lines.length === 0}
                  onClick={() => {
                    settle.mutate();
                  }}
                >
                  Mark settled
                </Button>
              )}
            </div>
          </div>
        )}
      </QueryState>
    </Modal>
  );
}

export function SettlementsPage() {
  const [date, setDate] = useState(() => istDaysAgo(1));
  const [openDriver, setOpenDriver] = useState<string | null>(null);
  const settlements = useSettlements(date);

  return (
    <>
      <PageHeader
        title="Settlements"
        description="One row per driver for the day (IST). Drafts update as trips and payments sync."
        actions={
          <Input
            aria-label="Day"
            type="date"
            className="w-44"
            max={istToday()}
            value={date}
            onChange={(e) => {
              if (e.target.value) setDate(e.target.value);
            }}
          />
        }
      />
      <Card>
        <QueryState query={settlements}>
          {(list) =>
            list.length === 0 ? (
              <EmptyState title={`No driver activity on ${fmtDate(date)}`} />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <Th>Driver</Th>
                    <Th align="right">Expected</Th>
                    <Th align="right">Cash</Th>
                    <Th align="right">Online</Th>
                    <Th align="right">Expenses</Th>
                    <Th align="right">Earnings</Th>
                    <Th align="right">Late items</Th>
                    <Th align="right">Net</Th>
                    <Th>Status</Th>
                  </tr>
                </thead>
                <tbody>
                  {list.map((s) => (
                    <SettlementRow
                      key={s.driverId}
                      s={s}
                      onOpen={() => {
                        setOpenDriver(s.driverId);
                      }}
                    />
                  ))}
                </tbody>
              </Table>
            )
          }
        </QueryState>
      </Card>
      {openDriver && (
        <SettlementDrawer
          date={date}
          driverId={openDriver}
          onClose={() => {
            setOpenDriver(null);
          }}
        />
      )}
    </>
  );
}
