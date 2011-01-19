require 'bundler/capistrano'

set :application, 'mawidabp'
set :repository,  'file:///home/franco/git/mawida_app'
set :deploy_to, '/var/rails/mawidabp'
set :user, 'deployer'
set :password, '!QAZxsw2'
set :group_writable, false
set :shared_children, %w(system log pids private public config)
set :use_sudo, false

set :scm, :git
set :branch, 'master'
set :local_repository, 'mawidaweb.com.ar:/home/franco/git/mawida_app'

set :bundle_without, [:test]

role :web, 'mawidaweb.com.ar' # Your HTTP server, Apache/etc
role :app, 'mawidaweb.com.ar' # This may be the same as your `Web` server
role :db,  'mawidaweb.com.ar', :primary => true # This is where Rails migrations will run

after 'deploy:symlink', 'deploy:update_crontab', 'deploy:create_shared_symlinks'

namespace :deploy do
  task :start do
  end

  task :stop do
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  desc 'Creates the symlinks for the shared folders'
  task :create_shared_symlinks do
    shared_paths = [['public', 'error_files'], ['private']]

    shared_paths.each do |path|
      shared_files_path = File.join(shared_path, *path)
      release_files_path = File.join(release_path, *path)

      run "ln -s #{shared_files_path} #{release_files_path}"
    end
  end

  desc 'Update the crontab file'
  task :update_crontab do
    run "cd #{release_path} && whenever --update-crontab #{application}"
  end
end