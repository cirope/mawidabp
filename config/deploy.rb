require 'bundler/capistrano'

set :whenever_command, 'bundle exec whenever'
require 'whenever/capistrano'

set :application, 'mawidabp'
set :repository,  'https://github.com/francocatena/mawida_app.git'
set :deploy_to, '/var/rails/mawidabp'
set :user, 'deployer'
set :group_writable, false
set :shared_children, %w(system log pids private public config)
set :use_sudo, false

set :scm, :git
set :branch, 'master'

set :bundle_without, [:test]

role :web, 'mawida.com.ar' # Your HTTP server, Apache/etc
role :app, 'mawida.com.ar' # This may be the same as your `Web` server
role :db,  'mawida.com.ar', :primary => true # This is where Rails migrations will run

after 'deploy:symlink', 'deploy:create_shared_symlinks',
  'deploy:precomplile_assets'

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
  
  desc 'precompile the assets'
  task :precomplile_assets, :roles => :web, :except => {:no_release => true} do
    run "cd #{current_path}; rm -rf public/assets/*"
    run "cd #{current_path}; RAILS_ENV=production bundle exec rake assets:precompile"
  end
end
