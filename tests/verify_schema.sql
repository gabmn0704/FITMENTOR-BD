DO $$
BEGIN
    IF to_regclass('public.users') IS NULL THEN
        RAISE EXCEPTION 'users table is missing';
    END IF;

    IF to_regclass('public.training_sessions') IS NULL THEN
        RAISE EXCEPTION 'training_sessions table is missing';
    END IF;

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
END $$;