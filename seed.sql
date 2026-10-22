-- Optional demo data for local development and CI only.
-- Every row is fake: names are prefixed with "DEMO", emails use the reserved
-- .invalid domain, and no google_id is set. Do not run this against production.
-- Safe to run more than once: rows with the same fixed ids are skipped.

BEGIN;

INSERT INTO users (id, name, email, level, goal, is_guest) VALUES
    ('a0000000-0000-4000-8000-000000000001', 'DEMO Atleta Uno', 'demo.uno@example.invalid', 'BEGINNER', 'Demo: ganar fuerza', false),
    ('a0000000-0000-4000-8000-000000000002', 'DEMO Atleta Dos', 'demo.dos@example.invalid', 'INTERMEDIATE', 'Demo: movilidad', false),
    ('a0000000-0000-4000-8000-000000000003', 'DEMO Invitado', 'guest-demo@example.invalid', 'BEGINNER', NULL, true)
ON CONFLICT DO NOTHING;

INSERT INTO training_sessions (id, user_id, exercise, repetitions, accuracy, calories, duration_seconds, avg_angles, created_at) VALUES
    ('b0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'SQUAT', 12, 88.50, 18.40, 240, '{"knee": 96.5, "hip": 112.0}', CURRENT_TIMESTAMP - INTERVAL '3 days'),
    ('b0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'PUSH_UP', 8, 75.00, 9.20, 180, '{"elbow": 91.0}', CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('b0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000002', 'SQUAT', 20, 94.25, 30.10, 420, '{"knee": 92.0, "hip": 105.5}', CURRENT_TIMESTAMP - INTERVAL '2 days')
ON CONFLICT DO NOTHING;

INSERT INTO user_achievements (user_id, achievement_id, unlocked_at) VALUES
    ('a0000000-0000-4000-8000-000000000001', 'DEMO_FIRST_SESSION', CURRENT_TIMESTAMP - INTERVAL '3 days')
ON CONFLICT DO NOTHING;

INSERT INTO routine_plans (id, user_id, level, rest_seconds, items, reason, created_at) VALUES
    ('c0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000002', 'INTERMEDIATE', 60,
     '[{"exercise": "SQUAT", "sets": 3, "reps": 12}, {"exercise": "PUSH_UP", "sets": 3, "reps": 8}]',
     'Demo: plan de ejemplo generado a mano', CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

COMMIT;
