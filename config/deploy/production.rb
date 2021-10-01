set :branch,    'c-dino'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@dino.mawidabp.com}
role :app, %w{deployer@dino.mawidabp.com}
role :db,  %w{deployer@dino.mawidabp.com}

server 'dino.mawidabp.com', user: 'deployer', roles: %w{web app db}
