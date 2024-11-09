set :branch,    'c-banco-del-chubut-test'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@banco-del-chubut-test.mawidabp.com}
role :app, %w{deployer@banco-del-chubut-test.mawidabp.com}
role :db,  %w{deployer@banco-del-chubut-test.mawidabp.com}

server 'banco-del-chubut-test.mawidabp.com', user: 'deployer', roles: %w{web app db}
