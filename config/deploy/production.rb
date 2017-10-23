set :stage, :production
set :rails_env, 'production'
set :branch, 'c-petersen-production'
set :pty, true

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@application.mawidabp.petersen.corp}
role :app, %w{deployer@application.mawidabp.petersen.corp}
role :db,  %w{deployer@application.mawidabp.petersen.corp}

server 'application.mawidabp.petersen.corp', user: 'deployer', roles: %w{web app db}
