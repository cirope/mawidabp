set :branch,    'c-hullop'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@hullop.mawidabp.com}
role :app, %w{deployer@hullop.mawidabp.com}
role :db,  %w{deployer@hullop.mawidabp.com}

server 'hullop.mawidabp.com', user: 'deployer', roles: %w{web app db}
