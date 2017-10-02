set :branch,    'c-bvalores'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'http_proxy':  'http://192.168.101.101:8080',
  'https_proxy': 'http://192.168.101.101:8080',
  'LANG':        'en_US.UTF-8',
  'LANGUAGE':    'en_US.UTF-8',
  'LC_ALL':      'en_US.UTF-8'
}

role :web, %w{deployer@127.0.0.1}
role :app, %w{deployer@127.0.0.1}
role :db,  %w{deployer@127.0.0.1}

server '127.0.0.1', user: 'deployer', roles: %w{web app db}
