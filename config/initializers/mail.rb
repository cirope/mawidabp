MawidaBP::Application.configure do
  config.action_mailer.raise_delivery_errors = !Rails.env.production?
  config.action_mailer.default_url_options = {
    host: APP_CONFIG['public_host'],
    protocol: (Rails.env.production? ? 'https' : 'http')
  }

  config.action_mailer.smtp_settings = APP_CONFIG['smtp'].symbolize_keys
end

ActionMailer::Base.register_observer(MailObserver)

