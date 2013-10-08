set :stage, :production

server 'mawidabp.com', user: 'deployer', roles: %w{web app db}
