set :branch,    'c-bice-production'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@bice-ba.mawidabp.com}
role :app, %w{deployer@bice-ba.mawidabp.com}
role :db,  %w{deployer@bice-ba.mawidabp.com}

server 'bice-ba.mawidabp.com', user: 'deployer', roles: %w{web app db}
