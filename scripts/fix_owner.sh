#!/usr/bin/env sh

set -eu

dir=$(cd "$(dirname "$0")" && pwd)

bundle exec rails runner $dir/fix_owner.rb
