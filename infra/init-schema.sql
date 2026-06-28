-- Extraordinary Profile Automation - Database Schema
-- Auto-executed by PostgreSQL on first run

CREATE TABLE IF NOT EXISTS profile_snapshots (
    id SERIAL PRIMARY KEY,
    snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
    followers INTEGER DEFAULT 0,
    following INTEGER DEFAULT 0,
    public_repos INTEGER DEFAULT 0,
    total_stars INTEGER DEFAULT 0,
    total_forks INTEGER DEFAULT 0,
    activity_score INTEGER DEFAULT 0,
    daily_events INTEGER DEFAULT 0,
    top_languages JSONB DEFAULT '{}',
    insights_json JSONB DEFAULT '[]',
    raw_profile JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(snapshot_date)
);

CREATE TABLE IF NOT EXISTS workflow_events (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    event_action VARCHAR(50),
    repository VARCHAR(255),
    payload JSONB,
    processed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS activity_log (
    id SERIAL PRIMARY KEY,
    log_level VARCHAR(10) DEFAULT 'INFO',
    source VARCHAR(100),
    message TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_snapshots_date ON profile_snapshots(snapshot_date DESC);
CREATE INDEX IF NOT EXISTS idx_events_type ON workflow_events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_created ON workflow_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_log_level ON activity_log(log_level);
CREATE INDEX IF NOT EXISTS idx_activity_created ON activity_log(created_at DESC);

-- View: Last 30 days trend
CREATE OR REPLACE VIEW v_last_30_days_trend AS
SELECT
    snapshot_date,
    followers,
    activity_score,
    daily_events,
    total_stars,
    LAG(followers) OVER (ORDER BY snapshot_date) as prev_followers,
    followers - LAG(followers) OVER (ORDER BY snapshot_date) as follower_change
FROM profile_snapshots
WHERE snapshot_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY snapshot_date DESC;

-- View: Weekly summary
CREATE OR REPLACE VIEW v_weekly_summary AS
SELECT
    DATE_TRUNC('week', snapshot_date) as week_start,
    AVG(activity_score)::INT as avg_score,
    SUM(daily_events) as total_events,
    MAX(followers) as max_followers,
    MAX(total_stars) as max_stars
FROM profile_snapshots
GROUP BY DATE_TRUNC('week', snapshot_date)
ORDER BY week_start DESC;
