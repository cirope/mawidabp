namespace :help do
  desc 'Install help dependencies'
  task install: :environment do
    Dir.chdir('config/jekyll') do
      Bundler.with_clean_env { %x{bundle install} }
    end
  end

  desc 'Run Jekyll in config/jekyll directory without having to cd there'
  task generate: :environment do
    Dir.chdir('config/jekyll') do
      Bundler.with_clean_env { %x{bundle exec jekyll build} }
    end
  end

  desc 'Run Jekyll in config/jekyll directory with --watch'
  task autogenerate: :environment do
    Dir.chdir('config/jekyll') do
      Bundler.with_clean_env { %x{bundle exec jekyll build --watch} }
    end
  end

  desc 'Link the generated help to public/help'
  task link: :environment do
    FileUtils.ln_s Rails.root.join('config/jekyll/_site'), Rails.root.join('public/help')
  end
end
