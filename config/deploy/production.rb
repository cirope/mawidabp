set :branch,    'interviews'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@app.mawidabp.com}
role :app, %w{deployer@app.mawidabp.com}
role :db,  %w{deployer@app.mawidabp.com}

server 'app.mawidabp.com', user: 'deployer', roles: %w{web app db}
