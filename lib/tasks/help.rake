namespace :help do
  desc 'Install help dependencies'
  task :install do
    Dir.chdir Rails.root.join('config/jekyll') do
      Bundler.with_unbundled_env do
        system 'bundle install' or raise 'install error!'
      end
    end
  end

  desc 'Run Jekyll in config/jekyll directory without having to cd there'
  task :generate do
    Dir.chdir Rails.root.join('config/jekyll') do
      system "BUNDLE_GEMFILE=#{Rails.root.join('config/jekyll/Gemfile')} /home/deployer/.rbenv/shims/bundle exec jekyll build" or raise 'generate error!'
    end
  end

  desc 'Run Jekyll in config/jekyll directory with --watch'
  task :autogenerate do
    Dir.chdir Rails.root.join('config/jekyll') do
      Bundler.with_unbundled_env do
        system 'bundle exec jekyll build --watch' or raise 'autogenerate error!'
      end
    end
  end

  desc 'Link the generated help to public/help'
  task :environment do
    FileUtils.ln_s Rails.root.join('config/jekyll/_site'), Rails.root.join('public/help')
  end
end
