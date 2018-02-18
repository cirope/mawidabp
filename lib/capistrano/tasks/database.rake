namespace :deploy do
  namespace :check do
    task linked_files: 'config/database.yml'
  end
end

namespace :config do
  desc 'Uploads config/database.yml.example as the initial database.yml'
  task :upload_database_config do
    on roles(:app) do
      config_path = 'config/database.yml'

      if test("[ -f #{shared_path.join config_path} ]")
        info "The #{config_path} file is already there"
      else
        info "Now edit the config file in #{shared_path.join config_path}"
        execute :mkdir, '-p', shared_path.join('config')
        upload! 'config/database.yml.example', shared_path.join(config_path)
      end
    end
  end
end
