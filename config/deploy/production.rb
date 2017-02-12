set :branch,    'master'
set :stage,     :production
set :rails_env, 'production'

role :web, %w{deployer@app.mawidabp.com}
role :app, %w{deployer@app.mawidabp.com}
role :db,  %w{deployer@app.mawidabp.com}

server 'app.mawidabp.com', user: 'deployer', roles: %w{web app db}
