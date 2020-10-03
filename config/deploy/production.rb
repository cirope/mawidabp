set :branch,    'c-bna-pla'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@bna-upla.mawidabp.com}
role :app, %w{deployer@bna-upla.mawidabp.com}
role :db,  %w{deployer@bna-upla.mawidabp.com}

server 'bna-upla.mawidabp.com', user: 'deployer', roles: %w{web app db}
