set :branch,    'c-bancotdf'
set :stage,     :production
set :rails_env, 'production'
set :pty,       true

set :default_env, {
  'http_proxy':  'http://rpm-proxy.bancotdf.com.ar:8080',
  'https_proxy': 'http://rpm-proxy.bancotdf.com.ar:8080'
}

set :ssh_options, {
  port: 22000
}

role :web, %w{deployer@127.0.0.1}
role :app, %w{deployer@127.0.0.1}
role :db,  %w{deployer@127.0.0.1}

server '127.0.0.1', user: 'deployer', roles: %w{web app db}
