set :stage, :sandbox
set :rails_env, 'sandbox'
set :branch, 'sandbox'

role :all, %w{localhost}

server 'localhost', user: 'deployer', roles: %w{web app db}, ssh_options: { port: 2222 }
