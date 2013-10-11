# Pesonalizado para cargar las configuraciones

DEFAULT_PARAMETERS = {
  :admin_blank_password_stale_days => 3,
  :admin_finding_stale_confirmed_days => '3',
  :admin_resource_units => [
    ['Hora', 0],
    ['Unidad', 1],
    ['$', 2],
    ['USD', 3],
    ['Otra', 4]
  ],
  :admin_review_code_expresion => '^(\\d){2}-[A-Z]{2}-(\\d){2}-(\\d){2}$',
  :security_acount_expire_time => '90',
  :security_allow_concurrent_sessions => '1',
  :security_attempts_count => '3',
  :security_expire_notification => '15',
  :security_password_constraint => '^(?=.*[a-zA-Z])(?=.*[0-9]).*$',
  :security_password_count => '12',
  :security_password_expire_time => '30',
  :security_password_minimum_length => '8',
  :security_password_minimum_time => '1',
  :security_session_expire_time => '15'
}.with_indifferent_access.freeze
