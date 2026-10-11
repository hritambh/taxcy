-- Sign-in with a password, and with Google once the Google account is linked to a
-- verified phone. The phone number stays the identity.
ALTER TABLE "users" ADD COLUMN "password_hash" TEXT;
ALTER TABLE "users" ADD COLUMN "email" TEXT;
ALTER TABLE "users" ADD COLUMN "google_sub" TEXT;
CREATE UNIQUE INDEX "users_google_sub_key" ON "users"("google_sub");
