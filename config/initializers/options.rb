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
  ] => 'evolution_down_success.png',
  [
    'Necesita mejorar',
    'Mantiene calificación desfavorable'
  ] => 'evolution_equal_warning.png'
}

NEW_CONCLUSION_EVOLUTION_IMAGES = {
  [
    'Satisfactorio',
    'Mejora calificación'
  ] => 'evolution_up_success_light.png',
  [
    'Satisfactorio con salvedades',
    'Mantiene calificación desfavorable'
  ] => 'evolution_equal_success_dark.png',
  [
    'Satisfactorio con salvedades',
    'Mejora calificación'
  ] => 'evolution_up_success_dark.png',
  [
    'Satisfactorio con salvedades',
    'Empeora calficación'
  ] => 'evolution_down_success_dark.png',
  [
    'Necesita mejorar',
    'Mantiene calificación desfavorable'
  ] => 'evolution_equal_warning.png',
  [
    'Necesita mejorar',
    'Mejora calificación'
  ] => 'evolution_up_warning.png',
  [
    'Necesita mejorar',
    'Empeora calficación'
  ] => 'evolution_down_warning.png',
  [
    'No satisfactorio',
    'Mantiene calificación desfavorable'
  ] => 'evolution_equal_danger.png',
  [
    'No satisfactorio',
    'Empeora calficación'
  ] => 'evolution_down_danger.png'
}

CONCLUSION_EVOLUTION = {
  'Satisfactorio' => [
    'Mantiene calificación favorable',
    'Mejora calificación',
    'No aplica - Primera revisión',
    'No aplica - Nuevo alcance',
    'No aplica'
  ],
  'Satisfactorio con salvedades' => [
    'Mantiene calificación favorable',
    'Mejora calificación',
    'Empeora calficación',
    'No aplica - Primera revisión',
    'No aplica - Nuevo alcance',
    'No aplica'
  ],
  'Necesita mejorar' => [
    'Mantiene calificación desfavorable',
    'Mejora calificación',
    'Empeora calficación',
    'No aplica - Primera revisión',
    'No aplica - Nuevo alcance',
    'No aplica'
  ],
  'No satisfactorio' => [
    'Mantiene calificación desfavorable',
    'Empeora calficación',
    'No aplica - Primera revisión',
    'No aplica - Nuevo alcance',
    'No aplica'
  ],
  'No aplica' => [
    'No aplica - Primera revisión',
    'No aplica - Nuevo alcance',
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

NEW_EVOLUTION_OPTIONS = [
  'Mantiene calificación desfavorable',
  'Mantiene calificación favorable',
  'Mejora calificación',
  'Empeora calficación',
  'No aplica - Primera revisión',
  'No aplica - Nuevo alcance'
]

EVOLUTION_IMAGES = {
  'Mantiene calificación desfavorable' => 'evolution_equal_danger.png',
  'Mantiene calificación favorable'    => 'evolution_equal_success.png',
  'Mejora calificación'                => 'evolution_up.png',
  'Empeora calficación'                => 'evolution_down.png',
  'No aplica'                          => 'evolution_not_apply.png'
}

NEW_EVOLUTION_IMAGES = {
  'Mantiene calificación favorable' => 'evolution_equal_success_light.png',
  'No aplica - Primera revisión'    => 'evolution_not_apply.png',
  'No aplica - Nuevo alcance'       => 'evolution_not_apply.png'
}

EVOLUTION_SUPERSCRIPT = 'evolution_footnote.png'

CONCLUSION_EVOLUTION_FOOTNOTES = {
  [
    'Satisfactorio con salvedades',
    'Empeora calficación'
  ] => '¹Se ha evidenciado algunos nuevos expuestos respecto de la revisión anterior, sin embargo, los mismos, aun así, permiten mantener una calificación favorable.'
}

NEW_CONCLUSION_EVOLUTION_FOOTNOTES = {
  [
    'Satisfactorio',
    'Mejora calificación'
  ] => '¹Se ha evidenciado la normalización de expuestos preexistentes, lo que ha impactado positivamente en la presente calificación respecto de nuestra revisión anterior.',
  [
    'Satisfactorio con salvedades',
    'Mantiene calificación desfavorable'
  ] => '¹Se ha evidenciado un ambiente de control interno que presenta oportunidades de mejora al igual que en nuestra revisión anterior.',
  [
    'Satisfactorio con salvedades',
    'Mejora calificación'
  ] => '¹Se ha evidenciado la normalización de expuestos preexistentes, lo que ha impactado positivamente en la presente calificación respecto de nuestra revisión anterior.',
  [
    'Satisfactorio con salvedades',
    'Empeora calficación'
  ] => '¹Se ha evidenciado, respecto de nuestra revisión anterior,  nuevos expuestos que debilitan el ambiente de control interno del proceso auditado.',
  [
    'Necesita mejorar',
    'Mantiene calificación desfavorable'
  ] => '¹Se ha evidenciado un ambiente de control interno que presenta oportunidades de mejora al igual que en nuestra revisión anterior.',
  [
    'Necesita mejorar',
    'Mejora calificación'
  ] => '¹Se ha evidenciado la normalización de expuestos preexistentes, lo que ha impactado positivamente en la presente calificación respecto de nuestra revisión anterior.',
  [
    'Necesita mejorar',
    'Empeora calficación'
  ] => '¹Se ha evidenciado, respecto de nuestra revisión anterior,  nuevos expuestos que debilitan el ambiente de control interno del proceso auditado.',
  [
    'No satisfactorio',
    'Mantiene calificación desfavorable'
  ] => '¹Se ha evidenciado un ambiente de control interno que presenta oportunidades de mejora al igual que en nuestra revisión anterior.',
  [
    'No satisfactorio',
    'Empeora calficación'
  ] => '¹Se ha evidenciado, respecto de nuestra revisión anterior,  nuevos expuestos que debilitan el ambiente de control interno del proceso auditado.',
}


EVOLUTION_FOOTNOTES = {
  'Mantiene calificación desfavorable' => '¹Se ha evidenciado un ambiente de control interno que presenta oportunidades de mejora al igual que en nuestra revisión anterior.',
  'Mantiene calificación favorable'    => '¹Se ha evidenciado un adecuado ambiente de control interno del proceso auditado, similar al de nuestra revisión anterior.',
  'Mejora calificación'                => '¹Se ha evidenciado la normalización de expuestos preexistentes, lo que ha impactado positivamente en la presente calificación respecto de nuestra revisión anterior.',
  'Empeora calficación'                => '¹Se ha evidenciado, respecto de nuestra revisión anterior, nuevos expuestos que debilitan el ambiente de control interno del proceso auditado.',
  'No aplica'                          => '¹El presente trabajo no puede compararse contra una revisión anterior porque se genera por primera vez o porque su actual alcance es distinto.'
}

NEW_EVOLUTION_FOOTNOTES = {
  'Mantiene calificación favorable' => '¹Se ha evidenciado un adecuado ambiente de control interno del proceso auditado, similar al de nuestra revisión anterior.',
  'No aplica - Primera revisión'    => '¹El presente trabajo no puede compararse contra una revisión anterior porque se genera por primera vez.',
  'No aplica - Nuevo alcance'       => '¹El presente trabajo no puede compararse contra una revisión anterior porque su actual alcance es distinto.'
}

PDF_IMAGE_PATH          = Rails.root.join('app', 'assets', 'images', 'pdf').freeze
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
