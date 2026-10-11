# Driver guide (mobile app)

> Describes the driver screens of the Taxcy app (built in M1.8; English and Hindi since M1.10). Owners and managers use the same app; see the [owner guide](owner-guide.md#owner-mode-in-the-app). Drivers use the Android or iOS app; the browser version (`bun run dev:driver-web`) is for demos and testing, and records the route only while its tab is open.

## Sign in

1. Open Taxcy and enter the mobile number your fleet owner registered.
2. Enter the OTP from the SMS.
3. Allow **camera** and **location** access. Location is used only while a trip is running.

### Language

The app speaks **English** and **हिन्दी (Hindi)**. It starts in your phone's language (Hindi if your phone is set to Hindi, otherwise English). To change it, tap the **translate** icon on the sign-in screen, or open the **⋮** menu on **My trips** and choose **Language**. The choice is saved on the phone. Amounts are shown in ₹ with Indian grouping (₹1,23,456) and dates in the chosen language.

If you are also the fleet owner (an owner-driver), the same **⋮** menu has **Owner mode**, which opens the fleet screens. Use **More → Driver mode** to come back. Your trips keep syncing and recording the route while you are in owner mode.

### One-time phone setup (important)

Some phones stop apps from running in the background to save battery. To make sure your trips are recorded correctly:

- **Settings → Apps → Taxcy → Battery → No restrictions** (on Xiaomi: "No restrictions"; on Oppo, Vivo and Realme: "Allow background activity").
- Keep **location** set to "Allow all the time" or "While using the app". The trip notification keeps the app active.

If GPS keeps getting cut off, your trips show as "inconclusive" to your owner.

## My trips

The home screen lists your trips for today and upcoming days. Tap a trip to see the pickup and drop points, the customer, the time, and the km included in the fare (if agreed).

## Create a trip

For a customer you pick up yourself, tap **New trip**: choose one way, round trip or local, enter the pickup and drop, start time and expected duration, the vehicle, the fare and, if agreed, the **included km**. The customer's name and number are optional. The trip is assigned to you and works offline; your owner sees it once your phone is online.

## Start a trip

1. Open the trip and tap **Start trip**.
2. Take a clear photo of the **odometer** with the in-app camera.
3. Type the odometer reading exactly as shown.
4. Tap **Start**. A notification shows the trip is running and your route is being recorded.

## During the trip

The **live trip** screen shows elapsed time and distance so far.

- **Add charge:** add tolls, parking, state tax and similar at any time, with an optional receipt photo. Mark **I paid this** if it came out of your pocket; it's paid back to you in your settlement.
- **Night charge, extra km and driver allowance** are extra fare: the customer pays them on top of the fare. There's no **I paid this** for them.
- **Request cancellation:** if the customer cancels mid-way, tap **Request cancellation**, enter the reason, and take an odometer photo. Your owner approves or rejects it. Until then the trip keeps running. You'll be notified of the decision.

## End a trip

1. Tap **End trip**.
2. Take a photo of the odometer and type the reading.
3. If the trip has included km and you've gone past them, the app says by how much; add an **Extra km** charge.
4. Add any other charges. The screen shows what the customer should pay: fare + extra fare + tolls and expenses. Charges and fuel added during the trip are listed too.
5. Enter what the customer paid: **Cash**, **UPI** or **Card**. You can split it, for example part cash and part UPI.
6. Tap **End**.

## Log a fuel fill

1. From the home screen, tap **Fuel** (or **Fuel** on a running trip). The vehicle is filled in from your trip: the running trip's car, otherwise the car on your next assigned trip (or a trip you finished in the last day). If you have trips in more than one car, choose among those. With no trip assigned, you can't log fuel; ask your fleet owner.
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
