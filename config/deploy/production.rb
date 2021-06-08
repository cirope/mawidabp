set :branch,    'c-patagonia-test'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@patagonia-gaps.mawidabp.com}
role :app, %w{deployer@patagonia-gaps.mawidabp.com}
role :db,  %w{deployer@patagonia-gaps.mawidabp.com}

server 'patagonia-gaps.mawidabp.com', user: 'deployer', roles: %w{web app db}
