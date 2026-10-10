-- Night charges, extra km and driver allowance are extra fare the customer pays on
-- top of the quoted fare; the driver never pays them out of pocket. Rows entered with
-- "paid by driver" on would wrongly reimburse the driver in settlement. Settled days
-- keep their frozen line items and aren't affected.
UPDATE "trip_charges"
SET "paid_by_driver" = false
WHERE "kind" IN ('night_charge', 'extra_km', 'driver_allowance')
  AND "paid_by_driver";
