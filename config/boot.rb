# Default Oracle locale
ENV['NLS_LANG'] ||= 'LATIN AMERICAN SPANISH_ARGENTINA.AL32UTF8'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
