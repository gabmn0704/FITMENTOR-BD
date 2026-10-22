CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    email VARCHAR(180) UNIQUE NOT NULL,
    level VARCHAR(30) NOT NULL DEFAULT 'BEGINNER',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Google sign-in and profile fields. Guest users keep a synthetic email.
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(64) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS picture TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS goal VARCHAR(60);
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_guest BOOLEAN DEFAULT false;

CREATE TABLE IF NOT EXISTS training_sessions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise VARCHAR(60) NOT NULL,
    repetitions INTEGER NOT NULL DEFAULT 0,
    accuracy NUMERIC(5,2) NOT NULL DEFAULT 0,
    calories NUMERIC(7,2) NOT NULL DEFAULT 0,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE training_sessions ADD COLUMN IF NOT EXISTS avg_angles JSONB DEFAULT '{}'::jsonb;

-- Databases created before this change have the FK without ON DELETE CASCADE.
-- Recreate it only when the existing action is not CASCADE ('c').
DO $$
DECLARE
    fk_action TEXT;
BEGIN
    SELECT c.confdeltype::TEXT INTO fk_action
    FROM pg_constraint c
    WHERE c.conrelid = 'public.training_sessions'::regclass
      AND c.conname = 'training_sessions_user_id_fkey';

    IF fk_action IS DISTINCT FROM 'c' THEN
        ALTER TABLE training_sessions DROP CONSTRAINT IF EXISTS training_sessions_user_id_fkey;
        ALTER TABLE training_sessions
            ADD CONSTRAINT training_sessions_user_id_fkey
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END $$;
