MawidaApp::Application.class_exec do
  config.action_mailer.default_url_options = { :host => URL_HOST }
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address => 'mawidaweb.com.ar',
    :domain => 'mawidaweb.com.ar',
    :port => 25,
    :user_name => 'soporte@mawidaweb.com.ar',
    :password => '5rdxcft6',
    :authentication => :plain
  }
end