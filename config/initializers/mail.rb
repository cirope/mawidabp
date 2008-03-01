ActionMailer::Base.default_charset = 'utf-8'
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.default_url_options[:host] = URL_HOST
ActionMailer::Base.smtp_settings = {
  :address => 'mawidaweb.com.ar',
  :domain => 'mawidaweb.com.ar',
  :port => 25,
  :user_name => 'soporte@mawidaweb.com.ar',
  :password => '5rdxcft6',
  :authentication => :plain
}