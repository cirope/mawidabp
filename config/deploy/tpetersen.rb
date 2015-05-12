set :stage, :production
set :rails_env, 'production'
set :branch, 'oracle'

role :web, %w{deployer@application.tmawidabp.petersen.corp}
role :app, %w{deployer@application.tmawidabp.petersen.corp}
role :db,  %w{deployer@application.tmawidabp.petersen.corp}

server 'application.tmawidabp.petersen.corp', user: 'deployer', roles: %w{web app db}
