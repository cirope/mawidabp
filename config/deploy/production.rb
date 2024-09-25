set :branch,    'c-btf-production'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@btf.mawidabp.com}
role :app, %w{deployer@btf.mawidabp.com}
role :db,  %w{deployer@btf.mawidabp.com}

server 'btf.mawidabp.com', user: 'deployer', roles: %w{web app db}
