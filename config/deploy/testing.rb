set :stage, :production
set :rails_env, 'production'
set :branch, 'c-petersen-test'
set :pty, true

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@application.tmawidabp.petersen.corp}
role :app, %w{deployer@application.tmawidabp.petersen.corp}
role :db,  %w{deployer@application.tmawidabp.petersen.corp}

server 'application.tmawidabp.petersen.corp', user: 'deployer', roles: %w{web app db}
