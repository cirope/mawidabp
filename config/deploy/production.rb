set :branch,    'c-patagonia-production'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@patagonia.mawidabp.com}
role :app, %w{deployer@patagonia.mawidabp.com}
role :db,  %w{deployer@patagonia.mawidabp.com}

server 'patagonia.mawidabp.com', user: 'deployer', roles: %w{web app db}
