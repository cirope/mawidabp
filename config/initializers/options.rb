COMPLIANCE_OPTIONS = {
  'yes' => { data: { tag: 'Compliance' } },
  'no'  => { data: { tag: 'Compliance', select: 'no' } }
}

CONCLUSION_OPTIONS = [
  'Satisfactorio',
  'Satisfactorio con salvedades',
  'Necesita mejorar',
  'No satisfactorio',
  'No aplica'
]

CONCLUSION_SCOPE_IMAGES = {
  'Satisfactorio'                => 'scope_success.png',
  'Satisfactorio con salvedades' => 'scope_success_with_exceptions.png',
  'Necesita mejorar'             => 'scope_warning.png',
  'No satisfactorio'             => 'scope_danger.png',
  'No aplica'                    => 'scope_not_apply.png'
}

CONCLUSION_IMAGES = {
  'Satisfactorio'                => 'score_success.png',
  'Satisfactorio con salvedades' => 'score_success_with_exceptions.png',
  'Necesita mejorar'             => 'score_warning.png',
  'No satisfactorio'             => 'score_danger.png',
  'No aplica'                    => 'score_not_apply.png'
}

CONCLUSION_EVOLUTION_IMAGES = {
  [
    'Satisfactorio con salvedades',
    'Mantiene calificación desfavorable'
  ] => 'evolution_equal_success.png',
  [
    'Satisfactorio con salvedades',
    'Empeora calficación'
  ] => 'evolution_down_success.png'
}

CONCLUSION_EVOLUTION = {
  'Satisfactorio' => [
    'Mantiene calificación favorable',
    'Mejora calificación',
    'No aplica'
  ],
  'Satisfactorio con salvedades' => [
    'Mantiene calificación favorable',
    'Mejora calificación',
    'Empeora calficación',
    'No aplica'
  ],
  'Necesita mejorar' => [
    'Mantiene calificación desfavorable',
    'Mejora calificación',
    'Empeora calficación',
    'No aplica'
  ],
  'No satisfactorio' => [
    'Mantiene calificación desfavorable',
    'Empeora calficación',
    'No aplica'
  ],
  'No aplica' => [
    'No aplica'
  ]
}

EVOLUTION_OPTIONS = [
  'Mantiene calificación desfavorable',
  'Mantiene calificación favorable',
  'Mejora calificación',
  'Empeora calficación',
  'No aplica'
]

EVOLUTION_IMAGES = {
  'Mantiene calificación desfavorable' => 'evolution_equal_danger.png',
  'Mantiene calificación favorable'    => 'evolution_equal_success.png',
  'Mejora calificación'                => 'evolution_up.png',
  'Empeora calficación'                => 'evolution_down.png',
  'No aplica'                          => 'evolution_not_apply.png'
}

PDF_IMAGE_PATH = Rails.root.join('app', 'assets', 'images', 'pdf').freeze
PDF_DEFAULT_SCORE_IMAGE = 'score_none.png'

PLAN_ITEM_STATS_EXCLUDED_SCOPES = [
  'Trabajo especial',
  'Informe de comité'
]

REVIEW_SCOPES = [
  'Auditorías/Seguimiento',
  'Trabajo especial',
  'Informe de comité',
  'Auditoría continua'
]

REVIEW_RISK_EXPOSURE = [
  'Alta',
  'Alta/media',
  'Media',
  'Media/baja',
  'Baja',
  'No relevante',
  'No aplica'
]

TAGS_READONLY = [
  'Eficiencia',
  'Experiencia al Cliente',
  'Fraude Interno',
  'Fraude Externo',
  'Riesgo Legal',
  'Compliance'
]

WEAKNESS_OPERATIONAL_RISK = {
  'Debilidad de control/errores' => {},
  'Fraude interno'               => { data: { tag: 'Fraude Interno' } },
  'Fraude externo'               => { data: { tag: 'Fraude Externo' } },
  'Riesgo legal'                 => { data: { tag: 'Riesgo Legal' } }
}

WEAKNESS_IMPACT = {
  'Reputacional'          => { data: { tag: 'Experiencia al Cliente' } },
  'Regulatorio'           => {},
  'Económico'             => { data: { tag: 'Eficiencia' } },
  'En el proceso/negocio' => {}
}

WEAKNESS_INTERNAL_CONTROL_COMPONENTS = [
  'Ambiente de control',
  'Evaluación de riesgos',
  'Actividades de control',
  'Administración y control contable',
  'Información y comunicación',
  'Monitoreo',
  'No aplica'
]
