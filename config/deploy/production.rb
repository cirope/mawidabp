set :branch,    'c-supervielle-production'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@spv.mawidabp.com}
role :app, %w{deployer@spv.mawidabp.com}
role :db,  %w{deployer@spv.mawidabp.com}

server 'spv.mawidabp.com', user: 'deployer', roles: %w{web app db}
