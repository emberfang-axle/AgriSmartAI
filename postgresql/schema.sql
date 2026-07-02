-- AgriSmartAI PostgreSQL Schema
-- Run: psql -d agrismartai -f postgresql/schema.sql

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Farmers
CREATE TABLE IF NOT EXISTS farmers (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,
    email       TEXT UNIQUE NOT NULL,
    phone       TEXT,
    barangay    TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Disease detections
CREATE TABLE IF NOT EXISTS detections (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id   UUID REFERENCES farmers(id) ON DELETE SET NULL,
    disease     TEXT NOT NULL,
    confidence  NUMERIC(5,2) NOT NULL,
    severity    TEXT NOT NULL,
    treatment   TEXT,
    prevention  TEXT,
    image_path  TEXT,
    reported    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id   UUID REFERENCES farmers(id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    body        TEXT NOT NULL,
    type        TEXT NOT NULL DEFAULT 'system',
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    data        JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Chat history
CREATE TABLE IF NOT EXISTS chat_messages (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id   UUID REFERENCES farmers(id) ON DELETE SET NULL,
    role        TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
    content     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Weather logs (caches fetched weather data for historical analysis)
CREATE TABLE IF NOT EXISTS weather_logs (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    temperature             NUMERIC(5,2) NOT NULL,
    humidity                INT NOT NULL,
    precipitation_prob      INT NOT NULL,
    wind_speed              NUMERIC(6,2) NOT NULL,
    weather_code            INT NOT NULL,
    condition               TEXT NOT NULL,
    fetched_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Disease risk predictions (weather-driven outbreak forecasts)
CREATE TABLE IF NOT EXISTS disease_predictions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    disease         TEXT NOT NULL,
    risk_level      TEXT NOT NULL CHECK (risk_level IN ('Low', 'Moderate', 'High')),
    confidence      INT NOT NULL CHECK (confidence BETWEEN 0 AND 100),
    factors         JSONB NOT NULL DEFAULT '[]',
    recommendation  TEXT NOT NULL,
    weather_log_id  UUID REFERENCES weather_logs(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Admin notification table (separate from farmer notifications)
CREATE TABLE IF NOT EXISTS admin_notifications (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title       TEXT NOT NULL,
    body        TEXT NOT NULL,
    type        TEXT NOT NULL DEFAULT 'system',
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    data        JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add address column to farmers if not already present
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS address TEXT;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_detections_farmer ON detections(farmer_id);
CREATE INDEX IF NOT EXISTS idx_detections_disease ON detections(disease);
CREATE INDEX IF NOT EXISTS idx_detections_created ON detections(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_farmer ON notifications(farmer_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_admin_notifs_read ON admin_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_admin_notifs_type ON admin_notifications(type);
CREATE INDEX IF NOT EXISTS idx_weather_logs_fetched ON weather_logs(fetched_at);
CREATE INDEX IF NOT EXISTS idx_predictions_created ON disease_predictions(created_at);

-- Seed admin farmer
INSERT INTO farmers (name, email, barangay)
VALUES ('DA Admin', 'admin@agrismartai.ph', 'New Bataan')
ON CONFLICT (email) DO NOTHING;
