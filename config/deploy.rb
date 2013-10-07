require 'bundler/capistrano'

set :whenever_command, 'bundle exec whenever'
require 'whenever/capistrano'

default_run_options[:shell] = '/bin/bash --login'

set :application, 'mawidabp'
set :user, 'deployer'
set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :group_writable, false
set :shared_children, %w(log)
set :use_sudo, false

set :repository,  'git://github.com/cirope/mawidabp.git'
set :branch, 'master'
set :scm, :git

server 'mawidabp.com', :web, :app, :db, primary: true

before 'deploy:finalize_update', 'deploy:create_shared_symlinks'

namespace :deploy do
  task :start do
  end

  task :stop do
  end

  task :restart, roles: :app, except: { no_release: true } do
    run "touch #{File.join current_path, 'tmp', 'restart.txt'}"
  end

  desc 'Creates the symlinks for the shared folders'
  task :create_shared_symlinks, roles: :app, except: {no_release: true} do
    shared_paths = [
      ['public', 'error_files'],
      ['private'],
      ['config', 'app_config.yml']
    ]

    shared_paths.each do |path|
      shared_files_path = File.join(shared_path, *path)
      release_files_path = File.join(release_path, *path)

      run "ln -s #{shared_files_path} #{release_files_path}"
    end
  end
end
