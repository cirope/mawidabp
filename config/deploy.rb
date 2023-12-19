set :application, 'mawidabp.com'
set :user, 'deployer'
set :repo_url, 'https://github.com/cirope/mawidabp.git'

set :format, :pretty
set :log_level, :info

set :deploy_to, "/MawidaFiles/#{fetch(:application)}"
set :deploy_via, :remote_cache

set :linked_files, %w{config/application.yml}
set :linked_dirs, %w{log private tmp/pids}

set :rbenv_type, :user
set :rbenv_ruby, '3.1.2'

set :keep_releases, 5

namespace :deploy do
  before :check,      'config:upload'
  before :publishing, :db_updates
  after  :publishing, :restart
  after  :finishing,  :help
  after  :finishing,  :cleanup
  after  :published,  'sidekiq:restart'
end
