COMPLIANCE_OPTIONS = {
  'yes' => { data: { tag: 'Compliance' } },
  'no'  => { data: { tag: 'Compliance', select: 'no' } }
}

COMPLIANCE_MAYBE_SANCTION_OPTIONS = {
  'no'  => false,
  'yes' => true
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

CONCLUSION_CHARTS = {
  'Satisfactorio'                => 'score_success_chart.png',
  'Satisfactorio con salvedades' => 'score_success_with_exceptions_chart.png',
  'Necesita mejorar'             => 'score_warning_chart.png',
  'No satisfactorio'             => 'score_danger_chart.png',
  'No aplica'                    => 'score_not_apply_chart.png'
}

CONCLUSION_CHART_LEGENDS = {
  'Satisfactorio'                => 'score_success_legend.png',
  'Satisfactorio con salvedades' => 'score_success_with_exceptions_legend.png',
  'Necesita mejorar'             => 'score_warning_legend.png',
  'No satisfactorio'             => 'score_danger_legend.png',
  'No aplica'                    => 'score_not_apply_legend.png'
}

CONCLUSION_CHART_LEGENDS_CHECKED = {
  'Satisfactorio'                => 'score_success_legend_checked.png',
  'Satisfactorio con salvedades' => 'score_success_with_exceptions_legend_checked.png',
  'Necesita mejorar'             => 'score_warning_legend_checked.png',
  'No satisfactorio'             => 'score_danger_legend_checked.png',
  'No aplica'                    => 'score_not_apply_legend_checked.png'
}

CONCLUSION_EVOLUTION_IMAGES = {
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

EVOLUTION_SUPERSCRIPT = 'evolution_footnote.png'

CONCLUSION_EVOLUTION_FOOTNOTES = {
  [
    'Satisfactorio con salvedades',
    'Empeora calficación'
  ] => '¹Desmejora (dentro de Satisfactorio) respecto a la auditoría anterior'
}

EVOLUTION_FOOTNOTES = {
  'Mantiene calificación desfavorable' => '¹Mantiene calificación desfavorable respecto a la auditoría anterior',
  'Mantiene calificación favorable'    => '¹Mantiene calificación favorable respecto a la auditoría anterior',
  'Mejora calificación'                => '¹Mejora calificación respecto a la auditoría anterior',
  'Empeora calficación'                => '¹Desmejora calificación respecto a la auditoría anterior',
  'No aplica'                          => '¹No puede compararse con un trabajo anterior'
}

PDF_IMAGE_PATH          = Rails.root.join('app', 'assets', 'images', 'pdf').freeze
PDF_GAL_IMAGE_PATH      = Rails.root.join('app', 'assets', 'images', 'gal_pdf').freeze
PDF_DEFAULT_SCORE_IMAGE = 'score_none.png'

PLAN_ITEM_STATS_EXCLUDED_SCOPES = [
  'Trabajo especial',
  'Informe de comité'
]

REVIEW_SCOPES = if USE_SCOPE_CYCLE
                  {
                    'Ciclo'      => { type: :cycle },
                    'Sustantivo' => { type: :sustantive }
                  }
                else
                  {
                    'Auditorías'         => {},
                    'Seguimiento'        => {},
                    'Trabajo especial'   => { require_tags: ['required_on_special_reviews'] },
                    'Informe de comité'  => {},
                    'Auditoría continua' => {}
                  }
                end

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

TAG_OPTIONS = {
  'finding' => {
    'Mínimo requerido'    => 'required_min_count',
    'Máximo requerido'    => 'required_max_count',
    'Requerido desde'     => 'required_from',
    'Incluir Descripción' => 'include_description'
  },
  'review' => {
    'Requerida en informes `Trabajo especial`' => 'required_on_special_reviews'
  },
  'user' => {
    'Usuario de recuperación' => 'recovery'
  }
}

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
