set :branch,    'c-prisma-test'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@prisma-test.mawidabp.com}
role :app, %w{deployer@prisma-test.mawidabp.com}
role :db,  %w{deployer@pristma-test.mawidabp.com}

server 'prisma-test.mawidabp.com', user: 'deployer', roles: %w{web app db}
