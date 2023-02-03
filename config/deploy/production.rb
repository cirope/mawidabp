set :branch,    'c-hipotecario-testing'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@banco-hipotecario-testing.mawidabp.com}
role :app, %w{deployer@banco-hipotecario-testing.mawidabp.com}
role :db,  %w{deployer@banco-hitotecario-testing.mawidabp.com}

server 'banco-hipotecario-testing.mawidabp.com', user: 'deployer', roles: %w{web app db}
