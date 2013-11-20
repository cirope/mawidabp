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
set :rbenv_ruby, '2.0.0-p247'

set :keep_releases, 5

namespace :deploy do
  after:finishing, 'deploy:cleanup'

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # execute 'service unicorn upgrade'
    end
  end

  # TODO: remove when whenever add support to Capistrano 3
  desc 'Update crontab with whenever'
  after :finishing, 'deploy:cleanup' do
    on roles(:all) do
      within release_path do
        execute :bundle, :exec, "whenever --update-crontab #{fetch(:application)}"
      end
    end
  end

  namespace :check do
    task linked_files: 'config/app_config.yml'
  end
end

remote_file 'config/app_config.yml' => '/tmp/app_config.yml', roles: :app

file '/tmp/app_config.yml' do |t|
  sh "curl -o #{t.name} https://raw.github.com/cirope/mawidabp/master/config/app_config.example.yml"
end
