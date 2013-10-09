# Pesonalizado para cargar las configuraciones

DEFAULT_PARAMETERS = {
  :admin_blank_password_stale_days => 3,
  :admin_code_prefix_for_oportunities => 'OM',
  :admin_code_prefix_for_nonconformities => 'NC',
  :admin_code_prefix_for_potential_nonconformities => 'NCP',
  :admin_code_prefix_for_fortresses => 'F',
  :admin_code_prefix_for_weaknesses => 'O',
  :admin_code_prefix_for_work_papers_in_control_objectives => 'PTOC',
  :admin_code_prefix_for_work_papers_in_oportunities => 'PTOM',
  :admin_code_prefix_for_work_papers_in_potential_nonconformities => 'PTNCP',
  :admin_code_prefix_for_work_papers_in_weaknesses => 'PTO',
  :admin_code_prefix_for_work_papers_in_fortresses => 'PTF',
  :admin_code_prefix_for_work_papers_in_weaknesses_follow_up => 'PTSO',
  :admin_code_prefix_for_work_papers_in_nonconformities => 'PTNC',
  :admin_finding_stale_confirmed_days => '3',
  :admin_priorities => [
    ['Baja', 0],
    ['Media', 1],
    ['Alta', 2]
  ],
  :admin_resource_units => [
    ['Hora', 0],
    ['Unidad', 1],
    ['$', 2],
    ['USD', 3],
    ['Otra', 4]
  ],
  :admin_review_code_expresion => '^(\\d){2}-[A-Z]{2}-(\\d){2}-(\\d){2}$',
  :admin_review_scores => [
    ['Satisfactorio', 80],
    ['Necesita mejorar', 50],
    ['No satisfactorio', 0]
  ],
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
