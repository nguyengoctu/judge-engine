CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE submissions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         VARCHAR(255) NOT NULL,
    problem_id      UUID NOT NULL,
    code            TEXT NOT NULL,
    language        VARCHAR(50) NOT NULL CHECK (language IN ('python', 'javascript', 'java')),
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'running', 'passed', 'failed', 'error')),
    results         JSONB DEFAULT NULL,
    execution_time  INTEGER DEFAULT NULL,
    memory_used     INTEGER DEFAULT NULL,
    competition_id  UUID DEFAULT NULL,
    submitted_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_submissions_user ON submissions(user_id);
CREATE INDEX idx_submissions_problem ON submissions(problem_id);
CREATE INDEX idx_submissions_status ON submissions(status);
CREATE INDEX idx_submissions_competition ON submissions(competition_id)
    WHERE competition_id IS NOT NULL;

CREATE TABLE competitions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    start_time      TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time        TIMESTAMP WITH TIME ZONE NOT NULL,
    problem_ids     UUID[] NOT NULL DEFAULT '{}',
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
