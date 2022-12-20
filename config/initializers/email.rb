Rails.application.configure do
  config.action_mailer.default_url_options = {
    host:     ENV['APP_HOST'],
    protocol: ENV['APP_PROTOCOL']
  }

  config.action_mailer.default_url_options[:port] = 3000 if Rails.env.development?

  config.action_mailer.smtp_settings = {
    address:              ENV['SMTP_ADDRESS'],
    port:                 ENV['SMTP_PORT'],
    domain:               ENV['SMTP_DOMAIN'].presence,
    user_name:            ENV['SMTP_USER_NAME'].presence,
    password:             ENV['SMTP_PASSWORD'].presence,
    authentication:       ENV['SMTP_AUTHENTICATION'].presence&.to_sym,
    enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'] != 'false',
    openssl_verify_mode:  OpenSSL::SSL::VERIFY_NONE
  }
end

ActionMailer::Base.register_observer ::MailObserver
