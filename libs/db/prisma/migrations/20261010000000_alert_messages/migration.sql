-- Alerts carry a translatable message ({ key, params }) next to the English
-- title and explanation. Existing alerts keep NULL and fall back to the text.
ALTER TABLE "alerts" ADD COLUMN "message" JSONB;
