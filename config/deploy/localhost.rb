set :stage, :production
set :rails_env, 'production'
set :branch, 'c-galicia-production'
set :log_level, :error

set :default_env, {
  'HTTP_PROXY':  'http://avhttp20.bancogalicia.com.ar:8080',
  'HTTPS_PROXY': 'http://avhttp20.bancogalicia.com.ar:8080',
  'PATH':        '$PATH:/usr/local/bin/',
  'LANG':        'en_US.UTF-8',
  'LANGUAGE':    'en_US.UTF-8',
  'LC_ALL':      'en_US.UTF-8'
}

role :web, %w{deployer@127.0.0.1}
role :app, %w{deployer@127.0.0.1}
role :db,  %w{deployer@127.0.0.1}

server '127.0.0.1', user: 'deployer', roles: %w{web app db}
