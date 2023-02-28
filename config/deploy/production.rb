set :branch,    'c-mariva-testing'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@mariva-test.mawidabp.com}
role :app, %w{deployer@mariva-test.mawidabp.com}
role :db,  %w{deployer@mariva-test.mawidabp.com}

server 'mariva-test.mawidabp.com', user: 'deployer', roles: %w{web app db}
