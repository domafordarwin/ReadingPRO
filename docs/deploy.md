# Deploy (Railway)

## Required environment variables
- DATABASE_URL: PostgreSQL connection string used by production (config/database.yml).
- RAILS_MASTER_KEY: decrypts config/credentials.yml.enc.
- SECRET_KEY_BASE: session/message verifier secret.
- RAILS_LOG_TO_STDOUT: set to 1 to send logs to stdout in production.
- RAILS_SERVE_STATIC_FILES: set to 1 to serve precompiled assets from /public.

## Notes
- Production database config uses `ENV["DATABASE_URL"]`.
- Credentials are loaded via `RAILS_MASTER_KEY` in production.

## Release (migrations)
- This app uses a Procfile `release` process to run `bundle exec rails db:migrate`.
- In Railway, ensure the service honors the Procfile release process; otherwise set the Railway Release Command to `bundle exec rails db:migrate`.
