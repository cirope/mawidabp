module Reports::AnnualReport
  include Reports::Pdf

  def annual_report
  end

  def create_annual_report
    @controller = 'conclusion'
    period = Period.list.find(params[:create_annual_report][:period_id])

    pdf = Prawn::Document.create_generic_pdf :portrait, margins: [30, 20, 20, 25]

    put_nbc_cover_on      pdf, Current.organization
    put_executive_summary pdf
    put_detailed_report   pdf

    save_pdf(pdf, @controller, period.start, period.end, 'annual_report')
    redirect_to_pdf(@controller, period.start, period.end, 'annual_report')
  end

  private

    def put_nbc_cover_on pdf, organization
      pdf.add_review_header organization, nil, nil

      pdf.move_down PDF_FONT_SIZE

      width       = pdf.bounds.width
      coordinates = [pdf.bounds.right - width, pdf.y - PDF_FONT_SIZE.pt * 14]
      text_title  = [
        I18n.t('conclusion_review.nbc.cover.title'),
        'Calificación del Control Interno de',
        'Nuevo Chaco Bursátil S.A.'
      ].join "\n"

      pdf.bounding_box(coordinates, width: width, height: 150) do
        pdf.text text_title, size: (PDF_FONT_SIZE * 1.5).round, align: :center, valign: :center, inline_format: true

        pdf.stroke_bounds
      end

      pdf.move_down PDF_FONT_SIZE * 10

      column_data  = [
        [I18n.t('conclusion_review.nbc.cover.issue_date'), I18n.l(Time.now, format: :long)  ],
        [I18n.t('conclusion_review.nbc.cover.to'), I18n.t('conclusion_review.nbc.cover.to_label')],
        [I18n.t('conclusion_review.nbc.cover.from'), I18n.t('conclusion_review.nbc.cover.from_label')],
        [I18n.t('conclusion_review.nbc.cover.cc'), 'cc' ]
      ]

      width_column1 = PDF_FONT_SIZE * 7
      width_column2 = pdf.bounds.width - width_column1

      pdf.table(column_data, cell_style: { inline_format: true }, column_widths: [width_column1, width_column2]) do
        row(0).style(
          borders: [:top, :left, :right]
        )
        row(1).style(
          borders: [:left, :right]
        )
        row(2).style(
          borders: [:bottom, :left, :right]
        )
      end

      pdf.move_down (pdf.y - PDF_FONT_SIZE.pt * 8)
      put_nbc_grid pdf

      pdf.start_new_page
    end

    def put_nbc_grid pdf
      column_data = [
        [
          I18n.t('conclusion_review.nbc.cover.number_review'),
          'AU - OPE 2021 - 48\nFebrero 2022',
          I18n.t('conclusion_review.nbc.cover.prepared_by')
        ]
      ]

      w_c = pdf.bounds.width / 3

      pdf.table(column_data, cell_style: { size: (PDF_FONT_SIZE * 0.75).round, inline_format: true },
                column_widths: w_c)
    end

    def put_executive_summary pdf
      pdf.text '<b><u>RESUMEN EJECUTIVO</u></b>', align: :center, inline_format: true

      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text '<b><u>OBJETIVO</u></b>', inline_format: true

      pdf.text 'El objetivo primario de nuestro informe es calificar el control interno de Nuevo Chaco Bursátil S.A. Las conclusiones a las que se arribaron en este informe derivan de las calificaciones de los distintos ciclos de negocios evaluados durante el periodo finalizado el 31 de Diciembre de 2021, y son válidas a la fecha de nuestra revisión, no abarcando posibles cambios posteriormente efectuados.'

      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text '<b><u>CONCLUSIÓN GENERAL</u></b>', inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text 'Con base en los resultados obtenidos de nuestras revisiones realizadas durante el periodo finalizado el 31 de diciembre de 2021, informamos a ustedes que, nuestra calificación general sobre el control interno de la Sociedad es de <b>“Requiere algunas mejoras”,</b><i> ver Cuadro I.</i>', inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text 'Para la determinación de esta calificación hemos evaluado las conclusiones de nuestras revisiones de los distintos ciclos de negocio de la Sociedad realizadas durante el ejercicio finalizado el 31 de diciembre de 2021.'

      pdf.move_down PDF_FONT_SIZE

      pdf.text 'Por otra parte, se realizó una evaluación de la situación actual del control interno de la entidad, tomando como base, el estado, a fecha del informe, de las observaciones detectadas en el presente ejercicio y las de seguimiento de informes anteriores.'

      pdf.move_down PDF_FONT_SIZE * 3

      pdf.table [[{ content: '', border_width: [0, 0, 1, 0] }]], column_widths: [140]

      pdf.move_down PDF_FONT_SIZE

      pdf.text '<b>AUS. Alejandro Camnasio</b>', inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text '<b>A/C int. Gerencia de Auditoria Interna</b>', inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text '<b>Nuevo Banco del Chaco S.A.</b>', inline_format: true

      pdf.start_new_page
    end

    def put_detailed_report pdf
      pdf.text '<b><u>INFORME DETALLADO</u></b>', align: :center, inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text '<b><u>INTRODUCCION Y ALCANCE DEL TRABAJO REALIZADO</u></b>', inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text 'Como parte de los procedimientos de revisión de control interno planificados en el marco del plan de Auditoría Interna del Nuevo Banco del Chaco S.A. para el ejercicio que finalizó el 31 de Diciembre de 2021, hemos realizado la calificación del control interno vigente en NCHB, partiendo de las conclusiones obtenidas de las revisiones de los distintos ciclos de negocio de la Entidad a la fecha de realización de las revisiones correspondientes.'

      pdf.move_down PDF_FONT_SIZE

      pdf.text 'La metodología de calificación de ciclos utilizada en el período 2019 fue aprobada por el Comité de Auditoría en su reunión del 14.05.2019 – Acta N° 294, la cual exponemos a continuación:'

      pdf.move_down PDF_FONT_SIZE

      put_cycle_qualification pdf

      pdf.move_down PDF_FONT_SIZE * 3

      pdf.text '<i><b>Cuadro I: Calificación del Control Interno del NCHB S.A. – Año 2021</b></i>', inline_format: true

      pdf.move_down PDF_FONT_SIZE * 2

      put_internal_control_qualification pdf

      pdf.move_down PDF_FONT_SIZE * 3

      pdf.text '<u><b>CONCLUSIONES</b></u>', inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text 'Partiendo del Cuadro I <i>“Calificación del Control Interno del NCHB S.A.”</i>, se observa que la calificación del control interno de la Entidad, de acuerdo a los parámetros utilizados, es <b>“Requiere algunas mejoras”.</b>', inline_format: true
    end

    def put_cycle_qualification pdf
      pdf.table [
        [
          { content: '<b>N°</b>', align: :center, size: 8, inline_format: true, background_color: '8DB4E2' },
          { content: '<b>Calificación</b>', align: :center, size: 8, inline_format: true, background_color: '8DB4E2' },
          { content: '<b>Ponderador</b>', align: :center, size: 8, inline_format: true, background_color: '8DB4E2' },
          { content: '<b>Cantidad de Observaciones de Riesgo Alto</b>', align: :center, size: 8, inline_format: true, background_color: '8DB4E2' }
        ],
        [
          { content: '1', size: 8 },
          { content: 'Adecuado', size: 8 },
          { content: '0-2', align: :center, size: 8 },
          { content: '0', align: :center, size: 8 }
        ],
        [
          { content: '2', size: 8 },
          { content: 'Requiere Algunas mejoras', size: 8 },
          { content: '3-15', align: :center, size: 8 },
          { content: '5', align: :center, size: 8 }
        ],
        [
          { content: '3', size: 8 },
          { content: 'Ajustado', size: 8 },
          { content: '16-50', align: :center, size: 8 },
          { content: '16', align: :center, size: 8 }
        ],
        [
          { content: '4', size: 8 },
          { content: 'Requiere mejoras significativas', size: 8 },
          { content: '51-150', align: :center, size: 8 },
          { content: '50', align: :center, size: 8 }
        ],
        [
          { content: '5', size: 8 },
          { content: 'Inadecuado', size: 8 },
          { content: '>150', align: :center, size: 8 },
          { content: '>50', align: :center, size: 8 }
        ],
      ], column_widths: [20, 170, 60, 180]
    end

    def put_internal_control_qualification pdf
      pdf.table [
        [
          { content: '<b>Ciclo</b>', align: :center, size: 8, inline_format: true, background_color: '8DB4E2', border_width: [1, 1, 2, 1] },
          { content: '<b>Cantidad de Observaciones</b>', align: :center, size: 8, inline_format: true, background_color: '8DB4E2', border_width: [1, 1, 2, 1] },
          { content: '<b>Ponderador a fecha de los Informes</b>', align: :center, size: 8, inline_format: true, background_color: '8DB4E2', border_width: [1, 1, 2, 1] },
          { content: '<b>Calificación</b>', align: :center, size: 8, inline_format: true, background_color: '8DB4E2', border_width: [1, 1, 2, 1] }
        ],
        [
          { content: 'Operativo', size: 8 },
          { content: '1', align: :center, size: 8 },
          { content: '0', align: :center, size: 8 },
          { content: 'Adecuado', size: 8 }
        ],
        [
          { content: 'TI', size: 8 },
          { content: '4', align: :center, size: 8 },
          { content: '12', align: :center, size: 8 },
          { content: 'Requiere algunas mejoras', size: 8 }
        ],
        [
          { content: 'PLAFT', size: 8 },
          { content: '7', align: :center, size: 8 },
          { content: '6', align: :center, size: 8 },
          { content: 'Requiere algunas mejoras', size: 8 }
        ],
        [
          { content: '', border_width: [2, 0, 2, 1] },
          { content: '', border_width: [2, 0, 2, 0] },
          { content: '', border_width: [2, 0, 2, 0] },
          { content: '', border_width: [2, 1, 2, 0] }
        ],
        [
          { content: '<b>Total ponderación</b>', size: 8, inline_format: true, background_color: '8DB4E2', border_width: [2, 0, 1, 1] },
          { content: '', background_color: '8DB4E2', border_width: [2, 0, 1, 0] },
          { content: '', background_color: '8DB4E2', border_width: [2, 1, 1, 0] },
          { content: '<b>18</b>', size: 8, inline_format: true, align: :center, border_width: [2, 1, 1, 1] }
        ],
        [
          { content: '<b>Cantidad de ciclos</b>', size: 8, inline_format: true, background_color: '8DB4E2', border_width: [1, 0, 1, 1] },
          { content: '', background_color: '8DB4E2', border_width: [1, 0, 1, 0] },
          { content: '', background_color: '8DB4E2', border_width: [1, 1, 1, 0] },
          { content: '<b>3</b>', size: 8, inline_format: true, align: :center, border_width: [1, 1, 1, 1] }
        ],
        [
          { content: '<b>Ponderación</b>', size: 8, inline_format: true, background_color: '8DB4E2', border_width: [1, 0, 2, 1] },
          { content: '', background_color: '8DB4E2', border_width: [1, 0, 2, 0] },
          { content: '', background_color: '8DB4E2', border_width: [1, 1, 2, 0] },
          { content: '<b>6</b>', size: 8, inline_format: true, align: :center, border_width: [1, 1, 2, 1] }
        ],
        [
          { content: '<b>Calificación Control Interno</b>', size: 8, inline_format: true, background_color: '8DB4E2', border_width: [2, 0, 2, 1] },
          { content: '', background_color: '8DB4E2', border_width: [2, 0, 2, 0] },
          { content: '', background_color: '8DB4E2', border_width: [2, 1, 2, 0] },
          { content: '<b>Requiere algunas mejoras</b>', size: 8, inline_format: true, align: :center, border_width: [2, 1, 2, 1] }
        ]
      ], column_widths: [110, 110, 110, 110]
    end
end
