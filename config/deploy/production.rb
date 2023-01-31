set :branch,    'c-mariva-production'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@mariva.mawidabp.com}
role :app, %w{deployer@mariva.mawidabp.com}
role :db,  %w{deployer@mariva.mawidabp.com}

server 'mariva.mawidabp.com', user: 'deployer', roles: %w{web app db}
