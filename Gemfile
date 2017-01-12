source 'https://rubygems.org'

git_source :github do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include? '/'

  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 4.2.7.1'

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
gem 'dynamic_form'
gem 'acts_as_tree'
gem 'net-ldap'
gem 'rubyzip', require: 'zip'
gem 'prawn'
gem 'prawn-table'
gem 'figaro'
gem 'irreverent'
gem 'bootstrap-sass'
gem 'will_paginate'
gem 'will_paginate-bootstrap'
gem 'search_cop'
gem 'jbuilder'
gem 'sidekiq'
gem 'ruby-ntlm'
gem 'chartist-rails'

gem 'nakayoshi_fork' # TODO: remove when MRI GC gets fixed, see https://github.com/ko1/nakayoshi_fork

gem 'sass-rails'
gem 'uglifier'

gem 'unicorn'

gem 'where-or' # TODO: remove when Rails 5.0

group :development do
  gem 'unicorn-rails'
  gem 'web-console'
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
end

group :test do
  gem 'test_after_commit' # TODO: remove when Rails 5.0
  gem 'timecop'
end

group :development, :test do
  gem 'byebug'
end
