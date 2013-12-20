set :stage, :production
set :rails_env, 'production'
set :branch, 'master'

role :all, %w{162.243.200.92}

server '162.243.200.92', user: 'deployer', roles: %w{web app db}
