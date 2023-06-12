set :branch,    'c-comafi-test'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@comafi-test.mawidabp.com}
role :app, %w{deployer@comafi-test.mawidabp.com}
role :db,  %w{deployer@comafi-test.mawidabp.com}

server 'comafi-test.mawidabp.com', user: 'deployer', roles: %w{web app db}
