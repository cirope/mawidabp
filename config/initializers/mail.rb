MawidaBP::Application.config.action_mailer.default_url_options = {
  :host => URL_HOST
}
MawidaBP::Application.config.action_mailer.raise_delivery_errors =
  !Rails.env.production?
MawidaBP::Application.config.action_mailer.delivery_method = :smtp
MawidaBP::Application.config.action_mailer.smtp_settings = {
  :address => 'smtp.gmail.com',
  :domain => 'mawidabp.com',
  :port => 587,
  :user_name => 'soporte@mawidabp.com',
  :password => APP_CONFIG['smtp_password'],
  :authentication => :plain,
  :enable_starttls_auto => true
}

ActionMailer::Base.register_observer(MailObserver)

