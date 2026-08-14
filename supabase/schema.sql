-- ============================================================================
-- PLUTO Version 3.5 Private Alpha Telemetry & Behavioral Analytics Schema
-- ============================================================================

-- Enable UUID generation extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Testers Table
CREATE TABLE IF NOT EXISTS alpha_testers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tester_id TEXT UNIQUE NOT NULL,
    tester_name TEXT,
    device_name TEXT,
    device_model TEXT,
    macos_version TEXT,
    app_version TEXT,
    first_seen_at TIMESTAMPTZ DEFAULT now(),
    last_seen_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Sessions Table
CREATE TABLE IF NOT EXISTS alpha_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tester_id TEXT NOT NULL REFERENCES alpha_testers(tester_id) ON DELETE CASCADE,
    session_id TEXT UNIQUE NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    app_version TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Events Table (Idempotent via unique client-generated event_id)
CREATE TABLE IF NOT EXISTS alpha_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tester_id TEXT NOT NULL REFERENCES alpha_testers(tester_id) ON DELETE CASCADE,
    session_id TEXT NOT NULL REFERENCES alpha_sessions(session_id) ON DELETE CASCADE,
    event_id TEXT UNIQUE NOT NULL,
    event_name TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    properties_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    app_version TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. State Snapshots Table
CREATE TABLE IF NOT EXISTS alpha_state_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tester_id TEXT NOT NULL REFERENCES alpha_testers(tester_id) ON DELETE CASCADE,
    snapshot_id TEXT UNIQUE NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    app_version TEXT,
    snapshot_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Crashes & Diagnostics Table
CREATE TABLE IF NOT EXISTS alpha_crashes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tester_id TEXT NOT NULL REFERENCES alpha_testers(tester_id) ON DELETE CASCADE,
    session_id TEXT,
    timestamp TIMESTAMPTZ NOT NULL,
    app_version TEXT,
    macos_version TEXT,
    current_screen TEXT,
    exception_name TEXT,
    exception_reason TEXT,
    stack_trace TEXT,
    breadcrumbs_json JSONB DEFAULT '[]'::jsonb,
    diagnostic_metadata_json JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Performance Traces Table
CREATE TABLE IF NOT EXISTS alpha_performance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tester_id TEXT NOT NULL REFERENCES alpha_testers(tester_id) ON DELETE CASCADE,
    session_id TEXT,
    trace_name TEXT NOT NULL,
    duration_ms DOUBLE PRECISION NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    metadata_json JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for lightning fast queries in the Creator Dashboard
CREATE INDEX IF NOT EXISTS idx_events_tester_ts ON alpha_events(tester_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_events_name ON alpha_events(event_name);
CREATE INDEX IF NOT EXISTS idx_events_created ON alpha_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_snapshots_tester ON alpha_state_snapshots(tester_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_crashes_tester ON alpha_crashes(tester_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_performance_name ON alpha_performance(trace_name, timestamp DESC);

-- ============================================================================
-- 🔒 ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE alpha_testers ENABLE ROW LEVEL SECURITY;
ALTER TABLE alpha_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE alpha_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE alpha_state_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE alpha_crashes ENABLE ROW LEVEL SECURITY;
ALTER TABLE alpha_performance ENABLE ROW LEVEL SECURITY;

-- 1. Deny ALL public / anon direct client access
-- (Edge Function runs with service_role and bypasses RLS for inserting)

-- 2. Allow Authenticated Creator access for Dashboard reads
CREATE POLICY "Creator read access on testers" ON alpha_testers
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Creator read access on sessions" ON alpha_sessions
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Creator read access on events" ON alpha_events
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Creator read access on snapshots" ON alpha_state_snapshots
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Creator read access on crashes" ON alpha_crashes
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Creator read access on performance" ON alpha_performance
    FOR SELECT TO authenticated USING (true);
