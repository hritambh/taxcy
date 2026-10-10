import { PayRule as PayRuleSchema, PhoneE164 } from '@taxcy/contracts';
import { UserPlus } from 'lucide-react';
import { useState, type SubmitEvent } from 'react';
import { useAuth } from '../auth/context.js';
import { PayRuleEditor } from '../components/PayRuleEditor.js';
import {
  Badge,
  Button,
  Card,
  EmptyState,
  Field,
  InlineError,
  Input,
  Modal,
  PageHeader,
  QueryState,
  Select,
  Table,
  Td,
  Th,
} from '../components/ui.js';
import { api, call } from '../lib/api.js';
import type { Driver, PayRule } from '../lib/api-types.js';
import { fmtPhone } from '../lib/format.js';
import { normalizeIndianMobile } from '../lib/labels.js';
import { describePayRule } from '../lib/money.js';
import { useApiMutation } from '../lib/mutations.js';
import { keys, useDefaultPayRule, useDrivers } from '../lib/queries.js';
import { DocumentsTable } from './DocumentsPage.js';

function InviteModal({ onClose }: { onClose: () => void }) {
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [phoneError, setPhoneError] = useState<string | null>(null);
  const invite = useApiMutation(
    (body: { name: string; phone: string }) => call(api.POST('/drivers', { body })),
    [keys.drivers],
  );

  function submit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    const normalized = normalizeIndianMobile(phone);
    if (!PhoneE164.safeParse(normalized).success) {
      setPhoneError('Enter a 10-digit Indian mobile number');
      return;
    }
    setPhoneError(null);
    invite.mutate({ name: name.trim(), phone: normalized }, { onSuccess: onClose });
  }

  return (
    <Modal open onClose={onClose} title="Invite a driver">
      <form onSubmit={submit} className="space-y-4">
        <p className="text-sm text-slate-600">
          The driver signs in to the Taxcy app with this number; no password needed.
        </p>
        <Field label="Name">
          {(props) => (
            <Input
              {...props}
              required
              value={name}
              onChange={(e) => {
                setName(e.target.value);
              }}
            />
          )}
        </Field>
        <Field label="Mobile number" error={phoneError}>
          {(props) => (
            <Input
              {...props}
              inputMode="tel"
              required
              placeholder="98123 45678"
              value={phone}
              onChange={(e) => {
                setPhone(e.target.value);
              }}
            />
          )}
        </Field>
        <InlineError error={invite.error} />
        <div className="flex justify-end gap-2">
          <Button variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" busy={invite.isPending} disabled={!name.trim()}>
            Send invite
          </Button>
        </div>
      </form>
    </Modal>
  );
}

function DriverModal({ driver, onClose }: { driver: Driver; onClose: () => void }) {
  const auth = useAuth();
  const defaultRule = useDefaultPayRule();
  const [name, setName] = useState(driver.name);
  const [status, setStatus] = useState(driver.status);
  const [override, setOverride] = useState(driver.payRule !== null);
  const [rule, setRule] = useState<PayRule | null>(driver.payRule);
  const [ruleError, setRuleError] = useState<string | null>(null);

  const update = useApiMutation(async () => {
    await call(
      api.PATCH('/drivers/{id}', {
        params: { path: { id: driver.id } },
        body: { name: name.trim(), status },
      }),
    );
    if (auth.isOwner) {
      const payRule = override ? rule : null;
      if (
        (payRule === null) !== (driver.payRule === null) ||
        JSON.stringify(payRule) !== JSON.stringify(driver.payRule)
      ) {
        await call(
          api.PUT('/drivers/{id}/pay-rule', {
            params: { path: { id: driver.id } },
            body: { payRule },
          }),
        );
      }
    }
  }, [keys.drivers, keys.settlements]);

  function save() {
    if (override && auth.isOwner) {
      const parsed = PayRuleSchema.safeParse(rule);
      if (!parsed.success) {
        setRuleError('Check the pay rule values');
        return;
      }
    }
    setRuleError(null);
    update.mutate(undefined, { onSuccess: onClose });
  }

  return (
    <Modal
      open
      wide
      onClose={onClose}
      title={driver.name}
      footer={
        <>
          <Button variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button busy={update.isPending} onClick={save}>
            Save
          </Button>
        </>
      }
    >
      <div className="space-y-6">
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Name">
            {(props) => (
              <Input
                {...props}
                value={name}
                onChange={(e) => {
                  setName(e.target.value);
                }}
              />
            )}
          </Field>
          <Field label="Status">
            {(props) => (
              <Select
                {...props}
                value={status}
                onChange={(e) => {
                  setStatus(e.target.value as Driver['status']);
                }}
              >
                <option value="active">Active</option>
                <option value="inactive">Inactive (can’t be assigned)</option>
              </Select>
            )}
          </Field>
        </div>

        <section>
          <h3 className="mb-2 text-sm font-semibold">Pay</h3>
          {!auth.isOwner && (
            <p className="mb-2 text-sm text-slate-600">Only the owner can change pay.</p>
          )}
          <label className="mb-3 flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              disabled={!auth.isOwner}
              checked={override}
              onChange={(e) => {
                setOverride(e.target.checked);
                if (e.target.checked && !rule && defaultRule.data) setRule(defaultRule.data);
              }}
            />
            Pay this driver differently from the default
            {defaultRule.data && (
              <span className="text-slate-500">({describePayRule(defaultRule.data)})</span>
            )}
          </label>
          {override && rule && (
            <PayRuleEditor value={rule} onChange={setRule} disabled={!auth.isOwner} />
          )}
          {ruleError && <p className="mt-2 text-xs text-red-600">{ruleError}</p>}
        </section>

        <DocumentsTable filter={{ driverId: driver.id }} subject={{ driverId: driver.id }} />
        <InlineError error={update.error} />
      </div>
    </Modal>
  );
}

export function DriversPage() {
  const drivers = useDrivers();
  const defaultRule = useDefaultPayRule();
  const [inviting, setInviting] = useState(false);
  const [editing, setEditing] = useState<Driver | null>(null);

  return (
    <>
      <PageHeader
        title="Drivers"
        actions={
          <Button
            onClick={() => {
              setInviting(true);
            }}
          >
            <UserPlus className="size-4" aria-hidden />
            Invite driver
          </Button>
        }
      />
      <Card>
        <QueryState query={drivers}>
          {(list) =>
            list.length === 0 ? (
              <EmptyState title="No drivers yet">
                Invite drivers by phone; they sign in with an OTP.
              </EmptyState>
            ) : (
              <Table>
                <thead>
                  <tr>
                    <Th>Name</Th>
                    <Th>Phone</Th>
                    <Th>Pay</Th>
                    <Th>Status</Th>
                    <Th />
                  </tr>
                </thead>
                <tbody>
                  {list.map((d) => (
                    <tr key={d.id} className="hover:bg-slate-50">
                      <Td className="font-medium">{d.name}</Td>
                      <Td>{fmtPhone(d.phone)}</Td>
                      <Td>
                        {d.payRule ? (
                          describePayRule(d.payRule)
                        ) : (
                          <span className="text-slate-500">
                            Default
                            {defaultRule.data ? ` · ${describePayRule(defaultRule.data)}` : ''}
                          </span>
                        )}
                      </Td>
                      <Td>
                        <span className="flex flex-wrap gap-1">
                          {d.status === 'active' ? (
                            <Badge tone="success">Active</Badge>
                          ) : (
                            <Badge>Inactive</Badge>
                          )}
                          {d.membershipStatus === 'invited' && (
                            <Badge tone="info">Hasn’t signed in yet</Badge>
                          )}
                        </span>
                      </Td>
                      <Td className="text-right">
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => {
                            setEditing(d);
                          }}
                        >
                          Manage
                        </Button>
                      </Td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            )
          }
        </QueryState>
      </Card>
      {inviting && (
        <InviteModal
          onClose={() => {
            setInviting(false);
          }}
        />
      )}
      {editing && (
        <DriverModal
          driver={editing}
          onClose={() => {
            setEditing(null);
          }}
        />
      )}
    </>
  );
}
