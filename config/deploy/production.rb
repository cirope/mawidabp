set :branch,    'master'
set :stage,     :production
set :rails_env, 'production'

role :web, %w{deployer@nevada2.mawidabp.com}
role :app, %w{deployer@nevada2.mawidabp.com}
role :db,  %w{deployer@nevada2.mawidabp.com}

server 'nevada2.mawidabp.com', user: 'deployer', roles: %w{web app db}
