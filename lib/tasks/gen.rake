namespace :help do
  desc 'Install help dependencies'
  task install: :environment do
    Dir.chdir("config/jekyll") do
      Bundler.with_clean_env { system('bundle install') }
    end
  end

  desc 'Run Jekyll in config/jekyll directory without having to cd there'
  task generate: :environment do
    Dir.chdir("config/jekyll") do
      Bundler.with_clean_env { system('bundle exec jekyll build') }
    end
  end

  desc 'Run Jekyll in config/jekyll directory with --watch'
  task autogenerate: :environment do
    Dir.chdir("config/jekyll") do
      Bundler.with_clean_env { system('bundle exec jekyll build --watch') }
    end
  end
end
