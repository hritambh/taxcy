# Owner guide (admin web)

> **(planned)** This guide describes the admin web as specified for milestone M1.7. Screens will be updated with screenshots when they're built.

The admin web is for **owners** and **managers**. Drivers use the [mobile app](driver-guide.md). Owners and managers can also run the fleet from the same app; see [Owner mode in the app](#owner-mode-in-the-app). A DCO (owner-driver) can do everything from the app.

## 1. Sign in

1. Go to the admin web and enter your mobile number.
2. Enter the 6-digit OTP you receive by SMS. In local development the OTP is printed in the API log.
3. If you belong to more than one organization, choose one. You can switch later from the top-right menu.

## 2. Set up your fleet

### Vehicles

**Fleet → Vehicles → Add vehicle**

- Registration number, make/model, year, and **fuel type** (petrol, diesel, CNG, or petrol + CNG). Fuel type is required and decides whether fuel is measured in litres or kg.
- Current odometer reading (optional, used to catch odometer rollbacks).

### Drivers

**Fleet → Drivers → Invite driver**

- Name and mobile number. The driver signs in to the app with that number; no password is needed.

### Documents

**Fleet → Documents**, or the Documents tab on a vehicle or driver.

- Add RC, insurance, permit and PUC for each vehicle, and a driving licence for each driver, with expiry dates and an optional photo or scan.
- When you renew a document, use **Renew** on the old one. That keeps the history and stops alerts for the old copy.
- You'll get alerts **30, 7 and 1 days** before expiry, and again on the day it expires.

## 3. Trips

### Create a trip

**Trips → New trip**

- Type: **One way**, **Round trip** or **Local rental**.
- Pickup and drop: type an address and drop the pin on the map (local rentals have no drop point).
- Scheduled start and end, customer name and phone, and the **quoted fare** in ₹.
- **Included km** (optional): the km the fare covers, e.g. 300 for a 300 km package. The trip page shows how far the trip went past it, and the driver is prompted to add an extra km charge.

Drivers can also create trips themselves in the app (for example a walk-in customer). Those are assigned to the driver, in the vehicle they picked, and the usual double-booking checks apply.

**Charges.** Night charges, extra km and driver allowance are extra fare: added to what the customer pays and never reimbursed to the driver. Tolls, parking, state tax and other charges are expenses, reimbursed to the driver when they paid.

### Assign

Pick a vehicle and driver. If either is already booked for an overlapping time, you'll see which trip conflicts.

### Track

The trip list shows each trip's status: Created → Assigned → Started → Ended → Settled (or Cancelled). The trip detail page shows:

- a timeline of every status change: who did it and when (device time and server time)
- start and end odometer photos, with the typed value and the OCR value
- the GPS route on a map, plus the **odometer vs GPS** result (OK / Flagged / Inconclusive)
- collections and charges (tolls, parking, etc.)

### Add or correct charges

On the trip detail page, **Charges → Add** lets you add tolls, parking, state tax, driver allowance, night charge or extra km, and mark whether the driver paid it out of pocket. Charges the driver added in the app also appear here, labelled with who entered them. You can void a wrong charge any time before the day is settled.

### Cancel

- **Not yet started:** **Cancel trip** asks for a reason and takes effect immediately. If the driver was offline, they'll see it as soon as their app syncs.
- **Already started:** the trip can only be cancelled with a reason and an approval. When a driver requests a cancellation, you'll get an alert, and the trip shows **Cancellation requested** with the reason and end-odometer photo. Choose:
  - **Approve**: optionally enter a cancellation fare (for example, to charge for the distance already driven). The trip becomes Cancelled.
  - **Reject**, with a note: the trip continues.

  You can also start a cancellation yourself on a running trip. You'll be asked for the reason, and the driver will be prompted for the end odometer.

## 4. Fuel

**Fuel → (pick a vehicle)**

- A list of fills: date, driver, quantity, cost, odometer, full-tank flag and receipt photo.
- A **cycles chart**: efficiency (km/L or km/kg) for each full-tank-to-full-tank cycle, with the vehicle's normal range shaded. Flagged cycles are shown in red.
- **Petrol + CNG cars** are charted as **cost per km (₹/km)** instead, because there's no way to tell how far they drove on each fuel. Here a _higher_ value is worse, and running on petrol when CNG is available shows up as a spike.
- Click a cycle to see the fills it includes and why it was or wasn't flagged.

**Getting accurate numbers:** ask drivers to fill **to full tank** regularly and to turn on "Full tank" in the app when they do. Efficiency can only be measured between two full-tank fills.

New vehicles use a typical figure for their model for the first 3 cycles. After that, Taxcy compares each vehicle against its own history.

## 5. Alerts

**Alerts** is your inbox for anything that needs attention:

| Alert                                              | What it means                                                                  |
| -------------------------------------------------- | ------------------------------------------------------------------------------ |
| Fuel use higher than usual                         | A fuel cycle was much worse than the vehicle's normal efficiency               |
| Odometer higher than GPS                           | A trip's odometer distance is well above the GPS-recorded route                |
| Document expiring / expired                        | RC, insurance, permit, PUC or DL is due                                        |
| Running cost higher than usual (petrol + CNG cars) | Cost per km in a cycle was much higher than the car's normal                   |
| Cancellation requested                             | A driver asked to cancel a running trip; approve or reject it on the trip page |

Each alert explains in plain language what happened and what to check. Mark it **Acknowledged**, **Resolved** or **Dismissed**. Dismissing a fuel alert as a false alarm lets that cycle count toward the vehicle's normal range.

## 6. Review queue

**Review** lists items where Taxcy isn't sure and needs a decision. Most often the photo and the typed number don't match. Each item shows the photo, the typed value and the value read from the photo. Choose:

- **Keep typed value**
- **Use value from photo**
- **Enter correct value**
- **Dismiss**

Fuel and distance checks are recalculated automatically after your decision.

## 7. Daily settlement

**Settlements → (pick a date)** shows one row per driver:

| Column          | Meaning                                                               |
| --------------- | --------------------------------------------------------------------- |
| Expected fare   | Quoted fares plus charges for trips that ended that day               |
| Cash            | Cash the driver collected                                             |
| Online          | UPI/card payments (already in your account)                           |
| Driver expenses | Fuel and tolls the driver paid from their pocket                      |
| Driver earnings | Per the driver's pay rule (see below)                                 |
| **Net payable** | What the driver hands over (or, if negative, what you owe the driver) |
| Shortfall       | Expected fare minus everything collected. It should be ₹0.            |

Open a row to see every item in it. Once you've received the cash, click **Mark settled**. A settled day is locked: anything the driver's phone syncs later appears in their next settlement as an adjustment.

## 8. Settings

**Settings → Audit**: fuel alert sensitivity (k standard deviations, minimum cycles, percentage threshold), odometer-vs-GPS tolerance, and document alert days. The defaults suit most fleets.

**Settings → Driver pay**: the default way drivers are paid in settlements:

| Option          | Example                                           |
| --------------- | ------------------------------------------------- |
| None            | Salaried drivers paid outside Taxcy               |
| Percent of fare | 20% of quoted fare (or of fare including charges) |
| Per trip        | ₹300 per trip                                     |
| Per km          | ₹2 per km driven                                  |
| Fixed daily     | ₹800 for any day with at least one trip           |

Turn **Driver allowance goes to driver** on if the bata customers pay belongs to the driver. To give one driver a different arrangement, open **Fleet → Drivers → (driver) → Pay**. Changing a rule only affects days that haven't been settled yet.

## Owner mode in the app

The Taxcy app (the same one drivers use) has the admin console's features for owners and managers. Sign in with your number: owners and managers get the fleet screens straight away. An owner-driver (DCO) starts on their driver screens and switches with **⋮ → Owner mode**, and back with **More → Driver mode**; the app remembers the last choice.

| Tab           | What's there                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Dashboard** | Today's trips by status, open alerts by severity, items to review, documents due in the next 30 days, and the most urgent open alerts                                                                                                                                                                                                                                                                                                                         |
| **Trips**     | All trips, filtered by status, day, driver and vehicle. **New trip** creates one (optionally with included km and an assigned car and driver). A trip's page has assign / reassign / unassign, cancel, the driver's cancellation request (approve with an optional cancellation fare, or reject with a note), charges (add or void), payments, odometer photos with typed vs read values, the route on a map with the odometer-vs-GPS check, and the timeline |
| **Alerts**    | The inbox, filtered by status and kind: acknowledge, resolve or dismiss; fuel alerts can be dismissed as a false alarm                                                                                                                                                                                                                                                                                                                                        |
| **More**      | Vehicles (add, edit, deactivate; each with its documents, fuel audit and trips), Drivers (invite, edit, deactivate, pay), Members (invite and remove managers), Documents (add with a photo, renew), Fuel (each car's cycles on a chart, fills, void a fill with a reason), Review, Settlements (per day, per driver, **Mark settled**), Settings, Language, Sign out                                                                                         |

- **Charges:** night charge, extra km and driver allowance are extra fare the customer pays, so they have no "driver paid" option. Tolls, parking, state tax and other charges can be marked as paid by the driver (reimbursed in settlement).
- **Managers** can do everything above except change settings and pay: the audit thresholds, the default pay rule and a driver's own pay rule are shown read-only, and only the owner can invite or remove managers.
- **Language:** English or Hindi, from **More → Language** or **Settings**. Alert texts, settlement lines and review reasons are shown in the chosen language. Alerts raised before this feature existed show their original English text.
- **Needs a connection.** Unlike the driver screens, owner mode works online only: each screen loads fresh from the server, shows **Retry** if it can't, and refreshes when you pull down.
- On a tablet or the browser at desktop width the tabs move to a side rail.
