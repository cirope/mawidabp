set :stage, :production
set :rails_env, 'production'
set :branch, 'master'

role :all, %w{mawidabp.com}

server 'mawidabp.com', user: 'deployer', roles: %w{web app db}
