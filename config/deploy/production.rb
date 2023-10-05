set :branch,    'c-supervielle-test'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@supervielle-test.mawidabp.com}
role :app, %w{deployer@supervielle-test.mawidabp.com}
role :db,  %w{deployer@supervielle-test.mawidabp.com}

server 'supervielle-test.mawidabp.com', user: 'deployer', roles: %w{web app db}
