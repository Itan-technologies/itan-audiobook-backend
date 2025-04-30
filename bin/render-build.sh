#!/usr/bin/env bash
set -o errexit

# Install Ruby gems
bundle install

# Fix bin/rails permission (important!)
chmod +x bin/rails

# Run database migrations
bundle exec rails db:migrate
