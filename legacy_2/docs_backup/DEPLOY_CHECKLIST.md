# Deploy Checklist

- Remove hardcoded test password and accounts before pushing to remote.
  - app/controllers/sessions_controller.rb: TEST_PASSWORD
  - app/views/sessions/new.html.erb: test password hint text
- Remove or gate test account buttons on the login page.
  - app/views/sessions/new.html.erb: test account buttons section

