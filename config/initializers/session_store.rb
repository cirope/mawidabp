# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_Mawida_session',
  :secret      => '19ec1ea2af88c3e51924ba72be71ab9718933c0bdddc5d8904403c2aa0679df840fd50bae1bcbb76e5bcaed5f2f5da70f1802f905fe502a4ac08a1d6dca5c101'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store