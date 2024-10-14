set :branch,    'c-bcra-test'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@bcra-testing.mawidabp.com}
role :app, %w{deployer@bcra-testing.mawidabp.com}
role :db,  %w{deployer@bcra-testing.mawidabp.com}

server 'bcra-testing.mawidabp.com', user: 'deployer', roles: %w{web app db}
