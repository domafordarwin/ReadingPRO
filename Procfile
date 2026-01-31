release: bundle exec rails db:migrate:status && bundle exec rails db:seed 2>/dev/null || true
web: bundle exec rails server -b 0.0.0.0 -p ${PORT}
