set :branch,    'c-bi'
set :stage,     :production
set :rails_env, 'production'

role :web, %w{deployer@bi.mawidabp.com}
role :app, %w{deployer@bi.mawidabp.com}
role :db,  %w{deployer@bi.mawidabp.com}

server 'bi.mawidabp.com', user: 'deployer', roles: %w{web app db}
