-- Extensions must exist before the tables that use geography and gist exclusion.
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS btree_gist;
