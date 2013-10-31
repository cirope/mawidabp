# Pesonalizado para cargar las configuraciones

DEFAULT_SETTINGS = {
  :finding_stale_confirmed_days => '3',
  :review_code_expresion => '^(\\d){2}-[A-Z]{2}-(\\d){2}-(\\d){2}$',
  :account_expire_time => '90',
  :allow_concurrent_sessions => '1',
  :attempts_count => '3',
  :expire_notification => '15',
  :password_constraint => '^(?=.*[a-zA-Z])(?=.*[0-9]).*$',
  :password_count => '12',
  :password_expire_time => '30',
  :password_minimum_length => '8',
  :password_minimum_time => '1',
  :session_expire_time => '15'
}.with_indifferent_access.freeze
