set :branch,    'c-galicia-test'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'PATH':     '$PATH:/usr/local/bin/',
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@galicia.mawidabp.com}
role :app, %w{deployer@galicia.mawidabp.com}
role :db,  %w{deployer@galicia.mawidabp.com}

server 'galicia.mawidabp.com', user: 'deployer', roles: %w{web app db}
