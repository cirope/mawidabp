source 'http://rubygems.org'

gem 'rails', '3.0.7'

gem 'bundler'
# TODO: Eliminar cuando se corrija el error en Rails o Rake
gem 'rake', '0.8.7'
gem 'pg'
gem 'foreigner', '1.0.0'
gem 'ya2yaml'
gem 'memcache-client'
gem 'calendar_date_select', :git => 'https://github.com/paneq/calendar_date_select.git', :branch => 'rails3test'
gem 'mini_magick'
gem 'uuidtools'
gem 'newrelic_rpm'
gem 'validates_timeliness', '~> 3.0'
gem 'RedCloth'
gem 'whenever', :require => false
gem 'will_paginate', '~> 3.0.beta'
gem 'paper_trail'
gem 'paperclip'
gem 'rmagick'
gem 'gruff'
# Sólo para pdf-writer
gem 'color', :require => false
# Sólo para pdf-writer
gem 'transaction-simple', :require => false

source 'http://gems.github.com'
gem 'metaskills-pdf-writer', :require => 'pdf/writer'
gem 'mksm-rubyzip', :require => 'zip/zip'

group :production do
  gem 'smurf'
end

group :development do
  gem 'ruby-debug'
  gem 'capistrano'
  gem 'mongrel'
end

group :test do
  gem 'turn'
  gem 'ruby-prof'
end