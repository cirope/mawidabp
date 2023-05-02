set :branch,    'c-smg-test'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@smg-test.mawidabp.com}
role :app, %w{deployer@smg-test.mawidabp.com}
role :db,  %w{deployer@smg-test.mawidabp.com}

server 'smg-test.mawidabp.com', user: 'deployer', roles: %w{web app db}
