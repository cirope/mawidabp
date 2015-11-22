set :stage, :production
set :rails_env, 'production'
set :branch, 'master'

role :web, %w{deployer@mawidabp.com}
role :app, %w{deployer@mawidabp.com}
role :db,  %w{deployer@mawidabp.com}

server 'mawidabp.com', user: 'deployer', roles: %w{web app db}
