namespace :deploy do
  desc "Generate application's help"
  task :help do
    on roles(:web), in: :sequence, wait: 5 do
      within release_path do
        with rails_env: fetch(:rails_env) do
          rake 'help:install'
          rake 'help:generate'
        end
      end
    end
  end
end
