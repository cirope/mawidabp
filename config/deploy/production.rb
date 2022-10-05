set :branch,    'c-comercial'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@comercial.mawidabp.com}
role :app, %w{deployer@comercial.mawidabp.com}
role :db,  %w{deployer@comercial.mawidabp.com}

server 'comercial.mawidabp.com', user: 'deployer', roles: %w{web app db}
