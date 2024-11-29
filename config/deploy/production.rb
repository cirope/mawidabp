set :branch,    'c-bcra-production'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@bcra.mawidabp.com}
role :app, %w{deployer@bcra.mawidabp.com}
role :db,  %w{deployer@bcra.mawidabp.com}

server 'bcra.mawidabp.com', user: 'deployer', roles: %w{web app db}
