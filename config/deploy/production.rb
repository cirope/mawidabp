set :branch,    'c-macro-production'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@macro.mawidabp.com}
role :app, %w{deployer@macro.mawidabp.com}
role :db,  %w{deployer@macro.mawidabp.com}

server 'macro.mawidabp.com', user: 'deployer', roles: %w{web app db}
