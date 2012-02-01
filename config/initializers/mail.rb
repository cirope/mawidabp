MawidaApp::Application.config.action_mailer.default_url_options = {
  :host => URL_HOST
}
MawidaApp::Application.config.action_mailer.raise_delivery_errors =
  !Rails.env.production?
MawidaApp::Application.config.action_mailer.delivery_method = :smtp
MawidaApp::Application.config.action_mailer.smtp_settings = {
  :address => 'mawida.com.ar',
  :domain => 'mawida.com.ar',
  :port => 25,
  :user_name => 'soporte@mawida.com.ar',
  :password => APP_CONFIG['smtp_password'],
  :authentication => :plain
}

ActionMailer::Base.register_observer(MailObserver)