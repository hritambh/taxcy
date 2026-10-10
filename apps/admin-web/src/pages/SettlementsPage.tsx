import { useState } from 'react';
import { useTranslation } from 'react-i18next';
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
import type { SettlementSummary } from '../lib/api-types.js';
import { fmtDate, fmtDateTime, fmtInr, istDaysAgo, istToday } from '../lib/format.js';
import { describePayRule, netPayableText } from '../lib/money.js';
import { useApiMutation } from '../lib/mutations.js';
import { keys, useSettlement, useSettlements } from '../lib/queries.js';
import { settlementLineText } from '../lib/settlement-text.js';

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
  const { t } = useTranslation();
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
          {t('settlements.tripCount', { count: s.tripCount })}
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
          <span className="block text-xs text-red-700">
            {t('settlements.shortfallAmount', { amount: fmtInr(s.shortfallPaise) })}
          </span>
        )}
      </Td>
      <Td>
        <Badge tone={s.status === 'settled' ? 'success' : 'warning'}>
          {t(`enums.settlementStatus.${s.status}`)}
        </Badge>
      </Td>
    </tr>
  );
}

function SettlementDrawer({
  date,
  driverId,
  onClose,
}: {
  date: string;
  driverId: string;
  onClose: () => void;
}) {
  const { t } = useTranslation();
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
      title={
        detail.data
          ? t('settlements.drawerTitle', { driver: detail.data.driverName, date: fmtDate(date) })
          : t('settlements.settlement')
      }
    >
      <QueryState query={detail}>
        {(d) => (
          <div className="space-y-5">
            <dl className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              <Stat label={t('settlements.expectedFare')} value={fmtInr(d.expectedFarePaise)} />
              <Stat label={t('settlements.cashCollected')} value={fmtInr(d.cashPaise)} />
              <Stat label={t('settlements.onlineToYou')} value={fmtInr(d.onlinePaise)} />
              <Stat label={t('settlements.driverExpenses')} value={fmtInr(d.driverExpensesPaise)} />
              <Stat
                label={t('settlements.driverEarnings')}
                value={fmtInr(d.driverEarningsPaise)}
                hint={describePayRule(d.payRule)}
              />
              <Stat
                label={t('settlements.lateItems')}
                value={d.carriedAdjustmentPaise ? fmtInr(d.carriedAdjustmentPaise) : '—'}
              />
              <Stat
                label={t('settlements.shortfall')}
                value={fmtInr(d.shortfallPaise)}
                hint={t('settlements.shortfallHint')}
              />
              <Stat
                label={t('settlements.settlement')}
                value={<NetPayable paise={d.netPayablePaise} />}
              />
            </dl>
            <p className="rounded-md bg-slate-50 p-3 text-xs text-slate-600">
              {t('settlements.netFormula')}
            </p>
            <Table>
              <thead>
                <tr>
                  <Th>{t('settlements.col.item')}</Th>
                  <Th>{t('settlements.col.details')}</Th>
                  <Th align="right">{t('settlements.col.amount')}</Th>
                </tr>
              </thead>
              <tbody>
                {d.lines.map((line) => (
                  <tr key={`${line.refType}:${line.refId}`}>
                    <Td>{t(`enums.settlementLine.${line.refType}`)}</Td>
                    <Td>
                      {settlementLineText(line)}
                      {line.originalDate && (
                        <span className="block text-xs text-amber-700">
                          {t('settlements.syncedLate', { date: fmtDate(line.originalDate) })}
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
                  {t('settlements.settledAt', { when: fmtDateTime(d.settledAt) })}
                </p>
              ) : (
                <p className="text-sm text-slate-600">{t('settlements.markSettledHint')}</p>
              )}
              {d.status === 'draft' && (
                <Button
                  busy={settle.isPending}
                  disabled={d.lines.length === 0}
                  onClick={() => {
                    settle.mutate();
                  }}
                >
                  {t('settlements.markSettled')}
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
  const { t } = useTranslation();
  const [date, setDate] = useState(() => istDaysAgo(1));
  const [openDriver, setOpenDriver] = useState<string | null>(null);
  const settlements = useSettlements(date);

  return (
    <>
      <PageHeader
        title={t('settlements.title')}
        description={t('settlements.description')}
        actions={
          <Input
            aria-label={t('settlements.day')}
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
              <EmptyState title={t('settlements.noActivity', { date: fmtDate(date) })} />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <Th>{t('settlements.col.driver')}</Th>
                    <Th align="right">{t('settlements.col.expected')}</Th>
                    <Th align="right">{t('settlements.col.cash')}</Th>
                    <Th align="right">{t('settlements.col.online')}</Th>
                    <Th align="right">{t('settlements.col.expenses')}</Th>
                    <Th align="right">{t('settlements.col.earnings')}</Th>
                    <Th align="right">{t('settlements.col.lateItems')}</Th>
                    <Th align="right">{t('settlements.col.net')}</Th>
                    <Th>{t('settlements.col.status')}</Th>
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
