# Pesonalizado para cargar las configuraciones

DEFAULT_SETTINGS = {
  account_expire_time: { value: '90', validates: 'numericality' },
  allow_concurrent_sessions: { value: '1', validates: 'numericality' },
  attempts_count: { value: '3', validates: 'numericality' },
  brief_period_in_weeks: { value: '0', validates: 'numericality' },
  exchange_directory_path: { value: '/tmp', validates: 'presence' },
  expire_notification: { value: '15', validates: 'numericality' },
  finding_stale_confirmed_days: { value: '3', validates: 'numericality' },
  password_constraint: { value: '^(?=.*[a-zA-Z])(?=.*[0-9]).*$', validates: 'presence' },
  password_count: { value: '12', validates: 'numericality' },
  password_expire_time: { value: '30', validates: 'numericality' },
  password_minimum_length: { value: '8', validates: 'numericality' },
  password_minimum_time: { value: '1', validates: 'numericality' },
  require_manager_on_findings: { value: '0', validates: 'numericality' },
  review_code_expresion: { value: '^(\\d){2}-[A-Z]{2}-(\\d){2}-(\\d){2}$', validates: 'presence' },
  session_expire_time: { value: '15', validates: 'numericality' },
  show_follow_up_timestamps: { value: '1', validates: 'numericality' },
  show_print_date_on_pdfs: { value: '1', validates: 'numericality' },
  hide_import_from_ldap: { value: '0', validates: 'numericality' },
  skip_function_and_manager_from_ldap_sync: { value: '0', validates: 'numericality' },
  hide_obsolete_best_practices: { value: '0', validates: 'numericality' },
  hours_of_work_per_day: { value: '0', validates: 'numericality' },
  conclusion_review_receiver: { value: '_', validates: 'presence' },
  temporary_polls: { value: '0', validates: 'numericality' },
  finding_warning_expire_days: { value: '7,1', validates: 'presence' },
  finding_by_current_user: { value: '1', validates: 'numericality' }
}.with_indifferent_access.freeze
