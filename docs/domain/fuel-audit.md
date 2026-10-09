# Fuel audit

The core feature. All logic on this page is implemented as pure functions in `libs/domain/fuel` and covered by table-driven unit tests. Each worked example below is also a test case.

## Inputs

A `fuel_fill` records: vehicle, driver, fuel filled (`petrol` | `diesel` | `cng`), odometer km, quantity (millilitres or grams), cost (paise), receipt photo, `is_full_tank`, and time. Voided fills are ignored.

Units depend on the fuel: petrol and diesel are measured in **litres**, CNG in **kg**.

| Vehicle `fuel_type` | Audit track | Metric |
| --- | --- | --- |
| `petrol` | `petrol` | km/L (higher is better) |
| `diesel` | `diesel` | km/L |
| `cng` | `cng` | km/kg |
| `petrol_cng` | `bifuel_cost` | paise/km (lower is better), see [Bi-fuel vehicles](#bi-fuel-vehicles-petrol_cng-cost-per-km) |

The sections below describe single-fuel vehicles; bi-fuel vehicles follow the same structure with the differences noted in their own section.

## Full-tank-to-full-tank cycles

A **cycle** runs between two consecutive full-tank fills of the same fuel on the same vehicle.

- **distance** = closing fill odometer − opening fill odometer
- **fuel** = sum of quantities of every fill **after** the opening full fill, **up to and including** the closing full fill (partial fills in between count)
- **efficiency** = distance / fuel

Partial fills before a vehicle's first full fill are ignored, because there's no known starting level.

### Worked example: a normal cycle

| Fill | Odometer | Qty | Full? |
| --- | --- | --- | --- |
| F1 | 10,000 | 30 L | ✅ |
| F2 | 10,250 | 20 L | ❌ |
| F3 | 10,600 | 25 L | ✅ |

The cycle runs F1 → F3: distance = 600 km, fuel = 20 + 25 = 45 L, efficiency = **13.33 km/L**. F1's 30 L is not counted; it filled the tank *before* the cycle began.

### Invalid cycles

A cycle gets the verdict `invalid` and a review item, instead of an alert, when:

| Condition | Review item kind | Likely cause |
| --- | --- | --- |
| distance ≤ 0 | `odometer_regression` | Typo, or odometer tampering |
| efficiency > 1.5 × baseline mean | `implausible_efficiency` | A fill wasn't logged |
| distance > 3,000 km | `implausible_efficiency` | Missed fills or a wrong reading |

Invalid cycles never update the baseline.

### Out-of-order and late fills

Offline phones can sync a fill that belongs *between* existing fills. When a fill is recorded or voided, the `fuel-cycles` job:

1. Finds the earliest cycle the fill could affect: the latest full fill at or before it.
2. Marks that cycle and every later cycle `superseded_at = now()`.
3. Replays the baseline from the snapshot before the affected cycle and recomputes cycles forward.
4. Re-raises or auto-resolves fuel alerts to match the new verdicts (`dedupe_key` = `fuel:<closing_fill_id>`).

## Per-vehicle baseline

Each (vehicle, audit track) pair keeps an **exponentially weighted** mean and variance of its accepted cycle efficiencies. With α = `fuel_ewma_alpha` (default 0.3), for each accepted efficiency `x`:

```
δ     = x − mean
mean' = mean + α·δ
var'  = (1 − α)·(var + α·δ²)
σ     = √var
```

**Seeding.** A new vehicle starts from `fuel_baseline_defaults`, using the most specific match: org + model, then global + model, then global fuel-only. Indicative seeds:

| Vehicle | Fuel | Seed mean | Seed σ |
| --- | --- | --- | --- |
| Maruti Dzire | CNG | 24.0 km/kg | 2.5 |
| Toyota Innova Crysta | diesel | 11.5 km/L | 1.2 |
| Toyota Etios | petrol | 14.0 km/L | 1.5 |
| any | diesel / petrol / cng (fallback) | 13 / 13 / 20 | 2 / 2 / 3 |
| any petrol + CNG | `bifuel_cost` (fallback) | 420 paise/km | 40 |

**Flagged cycles don't train the baseline.** Otherwise steady theft would slowly become "normal". If an owner dismisses the alert as a false positive, the cycle is marked `included_in_baseline = true` and the baseline is replayed.

## Flagging

Let `n` be the number of accepted cycles before this one, `k` = `fuel_k_sigma` (default 2), `N` = `fuel_min_cycles` (default 3) and `p` = `fuel_pct_threshold` (default 20%).

| Phase | Rule | `method` |
| --- | --- | --- |
| `n ≥ N` | flag if `x < mean − k·σ` | `sigma` |
| `n < N` | flag if `x < seed_mean × (1 − p/100)` | `percent` |

`deviation` stores `(mean − x)/σ` for the sigma method, or the percentage shortfall for the percent method.

**Severity (proposed):**

| Condition | Severity |
| --- | --- |
| sigma: `k < z ≤ 1.5k`; percent: shortfall between p and 1.5p | `warning` |
| sigma: `z > 1.5k`; percent: shortfall > 1.5p | `critical` |

### Worked example: flagged cycle

The vehicle is a Dzire CNG with baseline mean 24.0 km/kg, σ = 1.5 and 6 prior cycles. The new cycle is 520 km on 28.6 kg, so x = 18.18 km/kg.

`z = (24.0 − 18.18)/1.5 = 3.88` > 1.5 × 2, so the cycle is flagged **critical**.

The alert explanation shown to the owner:

> **MH12 AB 1234 (Dzire, CNG) used more fuel than usual.** Between 3 Oct and 8 Oct it ran 520 km on 28.6 kg of CNG, which is 18.2 km/kg. This car usually does about 24.0 km/kg, so this is 24% worse than normal. That's roughly 6.9 kg (about ₹620) more CNG than expected. Fills in this period were logged by Ramesh K. Check the receipts and odometer photos.

Explanations are produced by a pure `explainFuelCycle(cycle, vehicle, context)` function, so their wording is unit-tested too.

## Bi-fuel vehicles (`petrol_cng`): cost per km

Decision D4. There's no way to know how many km a bi-fuel car drove on petrol and how many on CNG, so its km/kg or km/L isn't meaningful. Instead, these vehicles are audited on **cost per km** (the `bifuel_cost` track):

- **Cycle anchors:** consecutive **full CNG fills**. CNG is almost always filled to cylinder pressure, so these anchors are reliable.
- **distance** = closing CNG fill odometer − opening CNG fill odometer
- **cost** = sum of `cost_paise` of **every fill of either fuel** after the opening fill, up to and including the closing fill
- **metric** = cost / distance, in **paise per km**. Here *higher is worse*.

Baseline and flagging use the same EWMA and the same sigma/percent rules as other vehicles, with the direction inverted:

| Phase | Rule |
| --- | --- |
| `n ≥ N` | flag if `x > mean + k·σ` |
| `n < N` | flag if `x > seed_mean × (1 + p/100)` |

Running on petrol costs more per km than CNG, so heavy petrol use shows up as a cost/km spike. No separate petrol-share alert is needed.

**Known limitations:**

- The petrol tank's level is unknown at each anchor, so one petrol top-up can land in a different cycle from the driving it paid for. This is noise of at most one petrol fill per cycle.
- Fuel price changes shift the baseline. The EWMA absorbs a price change within about 3 cycles.

### Worked example: bi-fuel cycle

The vehicle is a Maruti Ertiga (petrol + CNG) with a baseline of 420 paise/km, σ = 30 and 5 prior cycles.

| Fill | Fuel | Odometer | Cost | Full? |
| --- | --- | --- | --- | --- |
| C1 | CNG | 50,000 | ₹800 | ✅ (opening) |
| P1 | petrol | 50,180 | ₹1,000 | ❌ |
| C2 | CNG | 50,400 | ₹850 | ✅ (closing) |

Distance = 400 km, cost = ₹1,000 + ₹850 = ₹1,850, so x = **462.5 paise/km**. Then `z = (462.5 − 420)/30 = 1.42`, which is below k = 2, so the cycle is **ok**.

If P1 had been ₹2,000, then x = 712.5 paise/km and z = 9.75, so the cycle is flagged **critical**:

> **MH12 CD 5678 (Ertiga, petrol + CNG) cost more to run than usual.** Between 3 Oct and 8 Oct it ran 400 km for ₹2,850 of fuel, which is ₹7.13/km. This car usually costs about ₹4.20/km, so this is 70% more than normal. ₹2,000 of that was petrol. Check whether the car was run on petrol unnecessarily, and check the receipts.

Indicative seed: Ertiga / Dzire petrol + CNG ≈ 420 paise/km, σ 40. Seeds should be reviewed when fuel prices change.

## Fuel-type validation

A fill's fuel must match the vehicle's `fuel_type`: `petrol` vehicles take petrol only, `diesel` diesel only, `cng` CNG only, and `petrol_cng` petrol or CNG. Mismatches are rejected with `422 FUEL_TYPE_MISMATCH`.
