# ODefault Oracle locale
ENV['NLS_LANG'] ||= 'LATIN AMERICAN SPANISH_ARGENTINA.AL32UTF8'

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
