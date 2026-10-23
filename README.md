# FitMentor Database

Esquema PostgreSQL y configuración de despliegue para los servicios de FitMentor.

## Esquema

`init.sql` es la única fuente del esquema. Es idempotente: se puede ejecutar varias veces sobre una base nueva o existente gracias a `CREATE TABLE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS` y `CREATE INDEX IF NOT EXISTS`.

| Objeto | Descripción |
|---|---|
| `users` | Perfiles de usuario. `email` es `NOT NULL UNIQUE`; incluye `google_id` (único, inicio de sesión con Google), `picture`, `goal` (máx. 60) e `is_guest` (`NOT NULL`). Los invitados usan un correo sintético único `guest-<uuid>@guest.fitmentor.local`. |
| `training_sessions` | Sesiones de entrenamiento con `avg_angles` (JSONB). Se borran en cascada al eliminar su usuario. |
| `user_achievements` | Logros desbloqueados por usuario (clave primaria compuesta `user_id`, `achievement_id`). |
| `routine_plans` | Planes de rutina generados para un usuario, con `items` en JSONB. |
| `user_stats` (vista) | Por usuario: total de sesiones, repeticiones, calorías y precisión media. Los usuarios sin sesiones aparecen con totales en cero y precisión `NULL`. |

Índices relevantes: `training_sessions_user_created_idx` sobre `(user_id, created_at DESC)`, `routine_plans_user_created_idx` sobre `(user_id, created_at DESC)` y el índice único de `users.google_id`, que ya lo cubre la restricción `UNIQUE`.

El backend lleva una copia idéntica de `init.sql` (`src/main/resources/db/schema.sql`) y la ejecuta en cada arranque con el perfil `render`; después Hibernate sólo valida el mapeo (`ddl-auto: validate`). Así una base recién aprovisionada se inicializa sola y una existente se actualiza. Si cambias `init.sql`, copia el archivo al backend.

### Datos de demostración

`seed.sql` inserta datos de demo claramente falsos (nombres con prefijo `DEMO`, correos en el dominio reservado `.invalid`, sin `google_id`). Es opcional, también es idempotente y está pensado solo para desarrollo local y CI. **No lo ejecutes en producción.**

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f init.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f seed.sql   # opcional, solo desarrollo
```

## Pruebas

`tests/verify_schema.sql` comprueba que existen las tablas, las columnas con su tipo, la relación de `training_sessions`, el borrado en cascada de las tablas de usuario, los índices y que la vista `user_stats` se puede consultar. Falla con un error si algo falta.

El workflow `.github/workflows/schema.yml` ejecuta en PostgreSQL 16 los pasos siguientes en este orden: aplicar `init.sql`, aplicarlo de nuevo (comprobación de idempotencia), ejecutar la verificación y cargar `seed.sql`. Se lanza en cada push y pull request a `main`.

Para repetirlo en local con PostgreSQL 16 (o `psql` contra una base de pruebas):

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f init.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f init.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f tests/verify_schema.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f seed.sql
```

## Despliegue en la nube

`render.yaml` es un Blueprint de Render que conecta los repositorios públicos de GitHub `FITMENTOR-BACKEND` (Java 21 / Spring Boot) y `FITMENTOR-IA` (Python / FastAPI), cada uno con su propio `Dockerfile`. Provisiona PostgreSQL y pasa a la API los valores de conexión privados de la base de datos y la URL del servicio de IA.

| Servicio | Tipo | Health check |
|---|---|---|
| `fitmentor-backend` | web | `/actuator/health` |
| `fitmentor-ai` | privado | `/health` |
| `fitmentor-postgres` | PostgreSQL 16 | — |

Variables que el Blueprint configura en el backend: `SPRING_PROFILES_ACTIVE=render`, `JWT_SECRET` (generado por Render), `FRONTEND_ORIGIN` y `GOOGLE_CLIENT_ID` (se piden al crear el Blueprint), los datos de conexión de PostgreSQL y `AI_SERVICE_URL` (`host:puerto` privado del servicio de IA; el backend le antepone `http://`). En el servicio de IA, `ANTHROPIC_API_KEY` es opcional: sin ella el coach responde con reglas.

Para desplegar, crea un nuevo Blueprint desde este repositorio en Render y autoriza el acceso a los tres repositorios de servicio.

El Blueprint usa planes de pago con computación y base de datos siempre activas. Revisa los precios actuales de Render antes de crear los recursos. La base de datos solo acepta conexiones desde la red privada de Render.

El frontend se despliega por separado con GitHub Pages. Su repositorio necesita tener Pages configurado en **GitHub Actions** una sola vez, antes del primer despliegue.
