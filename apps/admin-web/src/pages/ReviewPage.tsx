import { useState } from 'react';
import { Link } from 'react-router';
import { Photo } from '../components/shared.js';
import {
  Badge,
  Button,
  EmptyState,
  Field,
  InlineError,
  Input,
  Modal,
  PageHeader,
  QueryState,
  Select,
  Stat,
} from '../components/ui.js';
import { api, call } from '../lib/api.js';
import type { ReviewItem } from '../lib/api-types.js';
import { fmtDateTime, fmtInr, fmtKm, humanize, rupeesToPaise } from '../lib/format.js';
import { keys, useReviewItems } from '../lib/queries.js';
import { useApiMutation } from '../lib/mutations.js';

const KIND_LABELS: Record<ReviewItem['kind'], string> = {
  ocr_mismatch_odometer: 'Odometer photo doesn’t match the typed reading',
  ocr_mismatch_receipt: 'Receipt doesn’t match the typed amount',
  odometer_regression: 'Odometer went backwards',
  implausible_efficiency: 'Fuel figures look implausible',
  mock_location: 'Fake GPS location detected',
  orphan_evidence: 'Photo from a cancelled trip',
  clock_skew: 'Phone clock was wrong',
  upload_mismatch: 'Uploaded file didn’t match',
};

type Resolution = 'accepted_typed' | 'accepted_ocr' | 'corrected' | 'dismissed';

/** What the item's value measures; null when there is nothing to correct (accept or dismiss only). */
function valueKind(item: ReviewItem): 'km' | 'paise' | null {
  if (item.subjectType === 'odometer_reading') return 'km';
  if (item.subjectType === 'fuel_fill') return 'paise';
  return null;
}

function showValue(item: ReviewItem, value: string | null): string {
  if (value === null) return '—';
  const n = Number(value);
  if (Number.isNaN(n)) return value;
  const kind = valueKind(item);
  return kind === 'km' ? fmtKm(n) : kind === 'paise' ? fmtInr(n) : value;
}

function ReviewCard({
  item,
  onResolve,
  busy,
}: {
  item: ReviewItem;
  onResolve: (resolution: Resolution, correctedValue?: number) => void;
  busy: boolean;
}) {
  const [correcting, setCorrecting] = useState(false);
  const [value, setValue] = useState('');
  const kind = valueKind(item);
  const reason = typeof item.context['reason'] === 'string' ? item.context['reason'] : null;
  const tripId = typeof item.context['tripId'] === 'string' ? item.context['tripId'] : null;
  const parsed =
    kind === 'paise' ? rupeesToPaise(value) : /^\d+$/.test(value) ? Number(value) : null;
  const open = item.status === 'open';

  return (
    <article className="grid gap-4 rounded-lg border border-slate-200 bg-white p-4 shadow-xs sm:grid-cols-[minmax(0,1fr)_16rem]">
      <div className="space-y-3">
        <div className="flex flex-wrap items-center gap-2">
          <Badge tone="warning">{KIND_LABELS[item.kind]}</Badge>
          {!open && <Badge>{humanize(item.status)}</Badge>}
          <span className="ml-auto text-xs text-slate-500">{fmtDateTime(item.createdAt)}</span>
        </div>
        {reason && <p className="text-sm text-slate-700">{reason}</p>}
        {(item.typedValue !== null || item.ocrValue !== null) && (
          <dl className="grid grid-cols-2 gap-3">
            <Stat label="Typed by the driver" value={showValue(item, item.typedValue)} />
            <Stat label="Read from the photo" value={showValue(item, item.ocrValue)} />
          </dl>
        )}
        {tripId && (
          <Link className="text-sm text-brand-700 hover:underline" to={`/trips/${tripId}`}>
            Open trip
          </Link>
        )}
        {open && (
          <div className="flex flex-wrap gap-2 pt-1">
            {kind && (
              <Button
                size="sm"
                disabled={busy}
                onClick={() => {
                  onResolve('accepted_typed');
                }}
              >
                Keep typed value
              </Button>
            )}
            {kind && item.ocrValue !== null && (
              <Button
                size="sm"
                variant="secondary"
                disabled={busy}
                onClick={() => {
                  onResolve('accepted_ocr');
                }}
              >
                Use value from photo
              </Button>
            )}
            {kind && (
              <Button
                size="sm"
                variant="secondary"
                disabled={busy}
                onClick={() => {
                  setCorrecting(true);
                }}
              >
                Enter correct value
              </Button>
            )}
            <Button
              size="sm"
              variant="ghost"
              disabled={busy}
              onClick={() => {
                onResolve('dismissed');
              }}
            >
              {kind ? 'Dismiss' : 'Mark reviewed'}
            </Button>
          </div>
        )}
      </div>
      <Photo
        mediaId={item.mediaId}
        alt={KIND_LABELS[item.kind]}
        className="max-h-56 w-full rounded-md border border-slate-200 object-contain"
      />
      {correcting && (
        <Modal
          open
          onClose={() => {
            setCorrecting(false);
          }}
          title="Enter the correct value"
          footer={
            <>
              <Button
                variant="secondary"
                onClick={() => {
                  setCorrecting(false);
                }}
              >
                Cancel
              </Button>
              <Button
                disabled={parsed === null}
                busy={busy}
                onClick={() => {
                  if (parsed !== null) onResolve('corrected', parsed);
                  setCorrecting(false);
                }}
              >
                Save correction
              </Button>
            </>
          }
        >
          <Field
            label={kind === 'paise' ? 'Amount (₹)' : 'Odometer (km)'}
            hint="Fuel and distance checks are recalculated with this value."
          >
            {(props) => (
              <Input
                {...props}
                inputMode={kind === 'paise' ? 'decimal' : 'numeric'}
                value={value}
                onChange={(e) => {
                  setValue(e.target.value);
                }}
              />
            )}
          </Field>
        </Modal>
      )}
    </article>
  );
}

export function ReviewPage() {
  const [status, setStatus] = useState<ReviewItem['status'] | ''>('open');
  const items = useReviewItems(status || undefined);
  const resolve = useApiMutation(
    (input: { id: string; resolution: Resolution; correctedValue?: number }) =>
      call(
        api.POST('/review-items/{id}/resolve', {
          params: { path: { id: input.id } },
          body: {
            resolution: input.resolution,
            ...(input.correctedValue === undefined ? {} : { correctedValue: input.correctedValue }),
          },
        }),
      ),
    [keys.review, keys.alerts, keys.fuel, keys.trips],
  );

  return (
    <>
      <PageHeader
        title="Review"
        description="Items where Taxcy isn’t sure. Nothing here blocked the driver; your decision corrects the record."
        actions={
          <Select
            aria-label="Status"
            className="w-44"
            value={status}
            onChange={(e) => {
              setStatus(e.target.value as typeof status);
            }}
          >
            <option value="open">Open</option>
            <option value="">All</option>
            <option value="accepted_typed">Kept typed value</option>
            <option value="accepted_ocr">Used photo value</option>
            <option value="corrected">Corrected</option>
            <option value="dismissed">Dismissed</option>
          </Select>
        }
      />
      <InlineError error={resolve.error} />
      <QueryState query={items}>
        {(list) =>
          list.length === 0 ? (
            <EmptyState title={status === 'open' ? 'Nothing to review' : 'No items'} />
          ) : (
            <div className="space-y-3">
              {list.map((item) => (
                <ReviewCard
                  key={item.id}
                  item={item}
                  busy={resolve.isPending && resolve.variables.id === item.id}
                  onResolve={(resolution, correctedValue) => {
                    resolve.mutate({
                      id: item.id,
                      resolution,
                      ...(correctedValue === undefined ? {} : { correctedValue }),
                    });
                  }}
                />
              ))}
            </div>
          )
        }
      </QueryState>
    </>
  );
}
