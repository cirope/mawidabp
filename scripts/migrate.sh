#!/usr/bin/env sh

set -eu

dir=$(cd "$(dirname "$0")" && pwd)
retries=10
ruby_code="ActiveRecord::Base.connection.exec_query 'SELECT 1'"

until bundle exec rails runner "$ruby_code"  > /dev/null 2>&1 || [ $retries -eq 0 ]; do
  echo "Waiting for database server, $((retries--)) attempts remaining..."
  sleep 2
done

if [ $retries -eq 0 ]; then
  echo 'Unable to connect with database'
  exit 1
fi

echo 'Executing bundle exec rails db:migrate...'
bundle exec rails db:migrate

echo 'Executing bundle exec rails db:seed...'
bundle exec rails db:seed

echo 'Executing bundle exec rails db:update...'
bundle exec rails db:update

source "$dir/fix_owner.sh"
