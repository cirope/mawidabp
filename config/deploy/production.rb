set :stage, :production
role :all, %w{mawidabp.com}
server 'mawidabp.com', user: 'deployer'
