DO $$
DECLARE
    expected_table TEXT;
    expected_column RECORD;
    expected_fk TEXT;
BEGIN
    -- Tables
    FOREACH expected_table IN ARRAY ARRAY['users', 'training_sessions', 'user_achievements', 'routine_plans'] LOOP
        IF to_regclass('public.' || expected_table) IS NULL THEN
            RAISE EXCEPTION '% table is missing', expected_table;
        END IF;
    END LOOP;

    -- Columns with their expected data types
    FOR expected_column IN
        SELECT * FROM (VALUES
            ('users', 'id', 'uuid'),
            ('users', 'name', 'character varying'),
            ('users', 'email', 'character varying'),
            ('users', 'level', 'character varying'),
            ('users', 'created_at', 'timestamp with time zone'),
            ('users', 'google_id', 'character varying'),
            ('users', 'picture', 'text'),
            ('users', 'goal', 'character varying'),
            ('users', 'is_guest', 'boolean'),
            ('users', 'password_hash', 'character varying'),
            ('users', 'sessions_valid_after', 'timestamp with time zone'),
            ('training_sessions', 'id', 'uuid'),
            ('training_sessions', 'user_id', 'uuid'),
            ('training_sessions', 'exercise', 'character varying'),
            ('training_sessions', 'repetitions', 'integer'),
            ('training_sessions', 'accuracy', 'numeric'),
            ('training_sessions', 'calories', 'numeric'),
            ('training_sessions', 'duration_seconds', 'integer'),
            ('training_sessions', 'created_at', 'timestamp with time zone'),
            ('training_sessions', 'avg_angles', 'jsonb'),
            ('user_achievements', 'user_id', 'uuid'),
            ('user_achievements', 'achievement_id', 'character varying'),
            ('user_achievements', 'unlocked_at', 'timestamp with time zone'),
            ('routine_plans', 'id', 'uuid'),
            ('routine_plans', 'user_id', 'uuid'),
            ('routine_plans', 'level', 'character varying'),
            ('routine_plans', 'rest_seconds', 'integer'),
            ('routine_plans', 'items', 'jsonb'),
            ('routine_plans', 'reason', 'text'),
            ('routine_plans', 'created_at', 'timestamp with time zone')
        ) AS v(table_name, column_name, data_type)
    LOOP
        IF NOT EXISTS (
            SELECT 1
            FROM information_schema.columns c
            WHERE c.table_schema = 'public'
              AND c.table_name = expected_column.table_name
              AND c.column_name = expected_column.column_name
              AND c.data_type = expected_column.data_type
        ) THEN
            RAISE EXCEPTION 'column %.% (%) is missing or has the wrong type',
                expected_column.table_name, expected_column.column_name, expected_column.data_type;
        END IF;
    END LOOP;

    -- Columns the backend relies on being NOT NULL
    FOR expected_column IN
        SELECT * FROM (VALUES
            ('users', 'email'),
            ('users', 'is_guest'),
            ('training_sessions', 'avg_angles')
        ) AS v(table_name, column_name)
    LOOP
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns c
            WHERE c.table_schema = 'public'
              AND c.table_name = expected_column.table_name
              AND c.column_name = expected_column.column_name
              AND c.is_nullable = 'YES'
        ) THEN
            RAISE EXCEPTION 'column %.% must be NOT NULL', expected_column.table_name, expected_column.column_name;
        END IF;
    END LOOP;

    -- Unique email (guests use a synthetic unique address)
    IF NOT EXISTS (
        SELECT 1
        FROM pg_index i
        JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY (i.indkey)
        WHERE i.indrelid = 'public.users'::regclass
          AND i.indisunique
          AND a.attname = 'email'
    ) THEN
        RAISE EXCEPTION 'unique index on users(email) is missing';
    END IF;

    -- Original relationship
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_schema = 'public'
          AND table_name = 'training_sessions'
          AND constraint_name = 'training_sessions_user_id_fkey'
          AND constraint_type = 'FOREIGN KEY'
    ) THEN
        RAISE EXCEPTION 'training_sessions user relationship is missing';
    END IF;

    -- Every user-owned table must cascade deletes from users
    FOREACH expected_fk IN ARRAY ARRAY['training_sessions', 'user_achievements', 'routine_plans'] LOOP
        IF NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            WHERE c.conrelid = ('public.' || expected_fk)::regclass
              AND c.contype = 'f'
              AND c.confrelid = 'public.users'::regclass
              AND c.confdeltype = 'c'
        ) THEN
            RAISE EXCEPTION '% must reference users with ON DELETE CASCADE', expected_fk;
        END IF;
    END LOOP;

    -- Indexes
    IF NOT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE schemaname = 'public'
          AND tablename = 'training_sessions'
          AND indexname = 'training_sessions_user_created_idx'
    ) THEN
        RAISE EXCEPTION 'training_sessions_user_created_idx is missing';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE schemaname = 'public'
          AND tablename = 'routine_plans'
          AND indexname = 'routine_plans_user_created_idx'
    ) THEN
        RAISE EXCEPTION 'routine_plans_user_created_idx is missing';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_index i
        JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY (i.indkey)
        WHERE i.indrelid = 'public.users'::regclass
          AND i.indisunique
          AND a.attname = 'google_id'
    ) THEN
        RAISE EXCEPTION 'unique index on users(google_id) is missing';
    END IF;
END $$;

-- View: must exist, expose the aggregate columns and be queryable
DO $$
DECLARE
    expected_view_column TEXT;
BEGIN
    IF to_regclass('public.user_stats') IS NULL THEN
        RAISE EXCEPTION 'user_stats view is missing';
    END IF;

    FOREACH expected_view_column IN ARRAY ARRAY['user_id', 'total_sessions', 'total_repetitions', 'total_calories', 'avg_accuracy'] LOOP
        IF NOT EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'user_stats'
              AND column_name = expected_view_column
        ) THEN
            RAISE EXCEPTION 'user_stats.% is missing', expected_view_column;
        END IF;
    END LOOP;

    PERFORM 1 FROM user_stats LIMIT 1;
END $$;
