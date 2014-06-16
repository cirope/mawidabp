namespace :deploy do
  desc "Generate application's help"
  task :help do
    on roles(:web), in: :sequence, wait: 5 do
      within release_path do
        rake 'help:install'
        rake 'help:generate'
        rake 'help:link'
      end
    end
  end
end
