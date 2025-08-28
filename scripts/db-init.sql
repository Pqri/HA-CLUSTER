CREATE TABLE IF NOT EXISTS location_logs (
  id bigserial PRIMARY KEY,
  server_name text,
  location_name text,
  latitude double precision,
  longitude double precision,
  timestamp timestamptz DEFAULT now()
);
