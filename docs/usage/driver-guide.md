# Driver guide (mobile app)

> **(planned)** This guide describes the driver app as specified for milestone M1.8.

## Sign in

1. Open Taxcy and enter the mobile number your fleet owner registered.
2. Enter the OTP from the SMS.
3. Allow **camera** and **location** access. Location is used only while a trip is running.

### One-time phone setup (important)

Some phones stop apps from running in the background to save battery. To make sure your trips are recorded correctly:

- **Settings → Apps → Taxcy → Battery → No restrictions** (on Xiaomi: "No restrictions"; on Oppo, Vivo and Realme: "Allow background activity").
- Keep **location** set to "Allow all the time" or "While using the app". The trip notification keeps the app active.

If GPS keeps getting cut off, your trips show as "inconclusive" to your owner.

## My trips

The home screen lists your trips for today and upcoming days. Tap a trip to see the pickup and drop points, the customer, and the time.

## Start a trip

1. Open the trip and tap **Start trip**.
2. Take a clear photo of the **odometer** with the in-app camera.
3. Type the odometer reading exactly as shown.
4. Tap **Start**. A notification shows the trip is running and your route is being recorded.

## During the trip

The **live trip** screen shows elapsed time and distance so far.

- **Add charge:** add tolls, parking, state tax and similar at any time, with an optional receipt photo. Mark **I paid this** if it came out of your pocket; it's paid back to you in your settlement.
- **Request cancellation:** if the customer cancels mid-way, tap **Request cancellation**, enter the reason, and take an odometer photo. Your owner approves or rejects it. Until then the trip keeps running. You'll be notified of the decision.

## End a trip

1. Tap **End trip**.
2. Take a photo of the odometer and type the reading.
3. Enter what the customer paid: **Cash**, **UPI** or **Card**. You can split it, for example part cash and part UPI.
4. Add any tolls, parking or state tax you paid.
5. Tap **End**.

## Log a fuel fill

1. From the home screen, tap **Fuel**.
2. Take a photo of the **receipt**.
3. Take a photo of the **odometer** and type the reading.
4. Enter the quantity (litres, or kg for CNG) and the amount in ₹.
5. Turn on **Full tank** if the tank was filled completely. Please fill to full whenever you can; it keeps your fuel record accurate.
6. Choose who paid: **Me (cash)**, **Owner** or **Fuel card**.

## Working without network

Everything works offline. Trips, photos, fuel fills and payments are saved on the phone and sent automatically when you're back online.

The bar at the top shows:

| Indicator    | Meaning                                   |
| ------------ | ----------------------------------------- |
| 🟢 Synced    | Everything has been sent                  |
| 🟡 3 pending | 3 items waiting to be sent                |
| 🔴 Offline   | No network; items are saved on your phone |

Don't uninstall the app or clear its data while items are pending.

### If a trip was cancelled while you were offline

When your phone reconnects, you'll see **"This trip was cancelled by the owner"**. The trip moves to Cancelled, and any photos you took are still sent to the owner for their records.
