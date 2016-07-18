source 'https://rubygems.org'

gem 'rails', '~> 4.2.7'

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'responders'
gem 'mini_magick'
gem 'simple_form'
gem 'newrelic_rpm'
gem 'validates_timeliness', github: 'francocatena/validates_timeliness'
gem 'RedCloth'
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
gem 'bloggy', require: false
gem 'irreverent'
gem 'bootstrap-sass'
gem 'will_paginate'
gem 'will_paginate-bootstrap'
gem 'search_cop'
gem 'jbuilder'
gem 'sidekiq'
gem 'chartist-rails'

gem 'nakayoshi_fork' # TODO: remove when MRI GC gets fixed, see https://github.com/ko1/nakayoshi_fork

gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'sprockets'

gem 'unicorn'

gem 'capistrano'
gem 'capistrano-bundler'
gem 'capistrano-rails'
gem 'capistrano-rbenv'
gem 'capistrano-sidekiq'

group :development do
  gem 'unicorn-rails'
  gem 'web-console'
end

group :test do
  gem 'sqlite3'
  gem 'test_after_commit' # TODO: remove when Rails 5.0
  gem 'timecop'
end

group :development, :test do
  gem 'spring'
  gem 'byebug'
end

# Include database gems for the adapters found in the database configuration file
require 'erb'
require 'yaml'

database_file = File.join File.dirname(__FILE__), 'config/database.yml'

if File.exist? database_file
  database_config = YAML::load ERB.new(IO.read(database_file)).result
  adapters        = database_config.values.map { |c| c['adapter'] }.compact.uniq

  adapters.each do |adapter|
    case adapter
    when /postgresql/
      gem 'pg'
    when /oracle/
      group :development, :production do
        gem 'ruby-oci8'
        gem 'activerecord-oracle_enhanced-adapter'
      end
    end
  end
end
