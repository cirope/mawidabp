namespace :help do
  desc 'Install help dependencies'
  task :install do
    Dir.chdir('config/jekyll') do
      Bundler.with_unbundled_env do
        system 'bundle install' or raise 'install error!'
      end
    end
  end

  desc 'Create symlinks to the fonts and stylesheets folders of the boostrap gem'
  task :create_bootstrap_symlinks do
    Dir.chdir('config/jekyll') do
      Bundler.with_unbundled_env do
        bootstrap_path = `bundle show bootstrap`.chop
        fonts_path = './assets/fonts'
        stylesheets_path = './_sass/stylesheets'
        FileUtils.remove_dir(fonts_path) if File.exist?(fonts_path)
        FileUtils.remove_dir(stylesheets_path) if File.exist?(stylesheets_path)
        FileUtils.symlink("#{bootstrap_path}/assets/fonts/bootstrap", fonts_path)
        FileUtils.symlink("#{bootstrap_path}/assets/stylesheets", stylesheets_path)
      end
    end
  end

  desc 'Run Jekyll in config/jekyll directory without having to cd there'
  task :generate do
    Dir.chdir('config/jekyll') do
      Bundler.with_unbundled_env do
        system 'bundle exec jekyll build' or raise 'generate error!'
      end
    end
  end

  desc 'Run Jekyll in config/jekyll directory with --watch'
  task :autogenerate do
    Dir.chdir('config/jekyll') do
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
