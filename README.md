# FitMentor Database

PostgreSQL schema and deployment configuration for the FitMentor services.

## Schema

`init.sql` creates user profiles and training-session records. The schema is idempotent and is checked against PostgreSQL 16 by the repository workflow. The backend also applies the same schema at startup so a newly provisioned database is initialized automatically.

## Cloud deployment

`render.yaml` is a Render Blueprint that connects the public GitHub repositories `FITMENTOR-BACKEND` and `FITMENTOR-IA`, provisions PostgreSQL, and wires private database and AI-service connection values into the backend. In Render, create a new Blueprint from this repository and authorize access to all three service repositories.

The Blueprint uses paid, always-on compute and database plans. Review the current Render pricing before creating resources. The database is restricted to Render's private network.

The frontend deploys separately through GitHub Pages. Its repository needs Pages set to **GitHub Actions** once before the first deployment.