# ReadingPRO

Reading proficiency diagnostics and reader profile assessment.

## Local development
- Requires Ruby 3.4.x and PostgreSQL
- `bundle install`
- `bin/rails db:prepare`
- `bin/rails server`

## Environment variables
- `DATABASE_URL`: provided by the Railway Postgres plugin
- `RAILS_MASTER_KEY`: contents of `config/master.key`
- `RAILS_SERVE_STATIC_FILES=1`
- Optional Action Cable with Redis: set `CABLE_ADAPTER=redis` and `REDIS_URL`

## Railway deploy
1. Create a new Railway project from GitHub.
2. Add the Postgres plugin.
3. Set `RAILS_MASTER_KEY` and `RAILS_SERVE_STATIC_FILES` in Variables.
4. Set Deploy command to `bin/rails db:prepare`.
5. Start command uses the `Procfile` (`web`) or set `bundle exec puma -C config/puma.rb`.
