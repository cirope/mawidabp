set :application, 'mawidabp.com'
set :user, 'deployer'
set :repo_url, 'git://github.com/cirope/mawidabp.git'

set :deploy_to, "/var/www/#{fetch(:application)}"

set :format, :pretty
set :log_level, :info

set :deploy_via, :remote_cache
set :scm, :git

set :linked_files, %w{config/app_config.yml}
set :linked_dirs, %w{log private public/error_files}

set :rbenv_type, :user
set :rbenv_ruby, '2.1.0'

set :keep_releases, 5

namespace :deploy do
  after:finishing, 'deploy:cleanup'

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'service unicorn upgrade'
    end
  end
end
