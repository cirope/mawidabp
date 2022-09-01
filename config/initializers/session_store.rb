# Be sure to restart your server when you modify this file.

if SHARED_SESSION
  Rails.application.config.session_store :cookie_store, key: '_mbp_session',
                                                        domain: COOKIES_DOMAIN,
                                                        same_site: :strict
else
  Rails.application.config.session_store :cookie_store, key: '_mbp_session'
end
