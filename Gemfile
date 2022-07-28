source 'https://rubygems.org'

gem 'rails', '~> 6.1'

gem 'pg'
gem 'activerecord-nulldb-adapter'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'responders'
gem 'mini_magick'
gem 'simple_form'
gem 'newrelic_rpm'
gem 'validates_timeliness', git: 'https://github.com/adzap/validates_timeliness.git', tag: 'v6.0.0.beta2'
gem 'redcarpet'
gem 'whenever'
gem 'paper_trail'
gem 'carrierwave'
gem 'acts_as_tree'
gem 'net-ldap'
gem 'rubyzip', require: 'zip'
gem 'prawn'
gem 'prawn-table'
gem 'matrix'
gem 'clbustos-rtf', require: 'rtf'
gem 'figaro'
gem 'business_time'
gem 'bootstrap', '< 5'
gem 'font-awesome-sass'
gem 'will_paginate'
gem 'bootstrap-will_paginate'
gem 'jbuilder'
gem 'sidekiq', '< 6.0'
gem 'ruby-ntlm'
gem 'chartist-rails'
gem 'rails-controller-testing' # TODO: remove after decouple test from assigns
gem 'autoprefixer-rails', '< 10' # TODO: remove when all customers have node > 8
gem 'execjs', '< 2.8'
gem 'net-smtp', require: false
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'rexml'

gem 'nakayoshi_fork' # TODO: remove when MRI GC gets fixed, see https://github.com/ko1/nakayoshi_fork

gem 'reform-rails'

gem 'ruby-saml'

gem 'sassc'
gem 'sassc-rails'
gem 'uglifier'

gem 'unicorn'
gem 'unicorn-rails'
gem 'unicorn-worker-killer'

group :development do
  gem 'web-console'
  gem 'listen'
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'

  # Support for ed25519 ssh keys
  gem 'ed25519'
  gem 'bcrypt_pbkdf'

  gem 'bullet'
end

group :test do
  gem 'timecop'
end

group :development, :test do
  gem 'byebug'
end
