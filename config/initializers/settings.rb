# Pesonalizado para cargar las configuraciones

DEFAULT_SETTINGS = {
  finding_stale_confirmed_days: { value: '3', validates: 'numericality' },
  review_code_expresion: { value: '^(\\d){2}-[A-Z]{2}-(\\d){2}-(\\d){2}$', validates: 'presence' },
  account_expire_time: { value: '90', validates: 'numericality' },
  allow_concurrent_sessions: { value: '1', validates: 'numericality' },
  attempts_count: { value: '3', validates: 'numericality' },
  expire_notification: { value: '15', validates: 'numericality' },
  password_constraint: { value: '^(?=.*[a-zA-Z])(?=.*[0-9]).*$', validates: 'presence' },
  password_count: { value: '12', validates: 'numericality' },
  password_expire_time: { value: '30', validates: 'numericality' },
  password_minimum_length: { value: '8', validates: 'numericality' },
  password_minimum_time: { value: '1', validates: 'numericality' },
  session_expire_time: { value: '15', validates: 'numericality' },
  exchange_directory_path: { value: '/tmp', validates: 'presence' }
}.with_indifferent_access.freeze
