source 'https://rubygems.org'

git_source :github do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include? '/'

  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.4'

gem 'pg'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'responders'
gem 'mini_magick'
gem 'simple_form'
gem 'newrelic_rpm'
gem 'validates_timeliness', github: 'francocatena/validates_timeliness'
gem 'RedCloth'
gem 'redcarpet'
gem 'whenever'
gem 'paper_trail'
gem 'carrierwave'
gem 'acts_as_tree'
gem 'net-ldap'
gem 'rubyzip', require: 'zip'
gem 'prawn'
gem 'prawn-table'
gem 'figaro'
gem 'irreverent'
gem 'bootstrap-sass'
gem 'will_paginate'
gem 'bootstrap-will_paginate'
gem 'search_cop'
gem 'jbuilder'
gem 'sidekiq'
gem 'request_store'
gem 'ruby-ntlm'
gem 'chartist-rails'
gem 'rails-controller-testing' # TODO: remove after decouple test from assigns

gem 'nakayoshi_fork' # TODO: remove when MRI GC gets fixed, see https://github.com/ko1/nakayoshi_fork

gem 'sass-rails'
gem 'uglifier'

gem 'unicorn'

group :development do
  gem 'unicorn-rails'
  gem 'web-console'
  gem 'listen'
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'

  # Support for ed25519 ssh keys
  gem 'rbnacl'
  gem 'bcrypt_pbkdf'
end

group :test do
  gem 'timecop'
end

group :development, :test do
  gem 'byebug'
end
