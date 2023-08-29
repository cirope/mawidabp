set :branch,    'c-hipotecario'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@hipotecario.mawidabp.com}
role :app, %w{deployer@hipotecario.mawidabp.com}
role :db,  %w{deployer@hitotecario.mawidabp.com}

server 'hipotecario.mawidabp.com', user: 'deployer', roles: %w{web app db}
