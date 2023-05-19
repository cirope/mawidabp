module Reports::NbcInternalControlQualificationAsGroupOfCompanies
  include Reports::Pdf

  def nbc_internal_control_qualification_as_group_of_companies
    @form = NbcInternalControlQualificationAsGroupOfCompaniesForm.new new_internal_control_qualification_as_group_of_companies_report
  end

  def create_nbc_internal_control_qualification_as_group_of_companies
    @form = NbcInternalControlQualificationAsGroupOfCompaniesForm.new new_internal_control_qualification_as_group_of_companies_report

    if @form.validate(params[:nbc_internal_control_qualification_as_group_of_companies])
      @controller        = 'conclusion'
      period             = @form.period
      previous_period    = @form.previous_period
      organization_ids   = Organization.where(prefix: ORGANIZATIONS_WITH_INTERNAL_CONTROL_QUALIFICATION_REPORT).pluck(:id)
      organization       = Current.organization
      pdf                = Prawn::Document.create_generic_pdf :portrait,
                                                              margins: [30, 20, 20, 25]

      text_titles        = [
        I18n.t('conclusion_committee_report.nbc_internal_control_qualification_as_group_of_companies_report.front_page.first_title'),
        I18n.t('conclusion_committee_report.nbc_internal_control_qualification_as_group_of_companies_report.front_page.second_title')
      ]

      put_nbc_cover_on               pdf, organization, text_titles, @form
      put_nbc_executive_summary      pdf, organization, @form
      put_nbc_introduction_and_scope pdf, @form

      results_period_with_final_weaknesses          = qualification_results organization_ids, period, true
      results_previous_period_with_final_weaknesses = qualification_results organization_ids, previous_period, true
      results_period_with_not_final_weaknesses      = qualification_results organization_ids, period, false

      put_nbc_internal_control_qualification_and_conclusion_group_of_companies_report pdf, period, results_period_with_final_weaknesses

      put_nbc_comparision_to_previous_period pdf, period, previous_period, results_period_with_final_weaknesses, results_previous_period_with_final_weaknesses

      put_nbc_comparision_to_actual_situation pdf, period, results_period_with_final_weaknesses, results_period_with_not_final_weaknesses

      save_pdf pdf, @controller, period.start, period.end, 'nbc_internal_control_qualification_as_group_of_companies_report'
      redirect_to_pdf @controller, period.start, period.end, 'nbc_internal_control_qualification_as_group_of_companies_report'
    else
      render action: :nbc_internal_control_qualification_as_group_of_companies
    end
  end

  private

    def new_internal_control_qualification_as_group_of_companies_report
      OpenStruct.new(
        period_id: '',
        date: Date.today,
        cc: '',
        name: '',
        objective: '',
        conclusion: '',
        introduction_and_scope: '',
        business_unit_type_id: ''
      )
    end

    def qualification_results organization_ids, period, final
      result              = []
      business_unit_types = BusinessUnitType.where(organization: organization_ids).pluck(:name).uniq

      business_unit_types.each do |business_unit_type|
        statuses = [
          Finding::STATUS[:being_implemented],
          Finding::STATUS[:implemented_audited]
        ]

        weaknesses = Weakness
          .joins(:business_unit_type)
          .joins(control_objective_item: { review: :period })
          .where(
            business_unit_type: { name: business_unit_type },
            reviews: { periods: { name: period.name } },
            state: statuses,
            final: final
          )

        add_unit_qualification result, weaknesses, business_unit_type
      end

      result
    end

    def add_unit_qualification result, weaknesses, business_unit_type
      if weaknesses.present?
        reviews_count = weaknesses.pluck('reviews.id').uniq.count
        total_weight  = calculate_total_weight(weaknesses, reviews_count)

        result << {
          name: business_unit_type,
          count: weaknesses.count,
          total_weight: total_weight,
          qualification: calculate_qualification(total_weight)
        }
      end
    end

    def put_nbc_internal_control_qualification_and_conclusion_group_of_companies_report pdf, period, results_period_with_final_weaknesses
      pdf.move_down PDF_FONT_SIZE * 3

      pdf.text I18n.t('conclusion_committee_report.nbc_internal_control_qualification_as_group_of_companies_report.internal_control_qualification.classification_title',
                      period: period.name),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE * 2

      total_cycles = 0
      total_weight = 0
      table        = []

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_cycle'),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_count_findings'),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_weight'),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_qualification'),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        }
      ]

      results_period_with_final_weaknesses.each do |item|
        total_cycles += 1
        total_weight += item[:total_weight]

        table << [
          { content: item[:name], size: 8 },
          { content: item[:count].to_s, align: :center, size: 8 },
          { content: item[:total_weight].to_s, align: :center, size: 8 },
          { content: item[:qualification], size: 8 }
        ]
      end

      table << [
        { content: '', border_width: [2, 0, 2, 1] },
        { content: '', border_width: [2, 0, 2, 0] },
        { content: '', border_width: [2, 0, 2, 0] },
        { content: '', border_width: [2, 1, 2, 0] }
      ]

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.count_weight'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [2, 0, 1, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [2, 0, 1, 0] },
        { content: '', background_color: '8DB4E2', border_width: [2, 1, 1, 0] },
        {
          content: "<b>#{total_weight}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [2, 1, 1, 1]
        }
      ]

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.count_cycles'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 0, 1, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [1, 0, 1, 0] },
        { content: '', background_color: '8DB4E2', border_width: [1, 1, 1, 0] },
        {
          content: "<b>#{total_cycles}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [1, 1, 1, 1]
        }
      ]

      annual_weight        = (total_weight / (total_cycles.zero? ? 1 : total_cycles.to_f)).round
      annual_qualification = calculate_qualification annual_weight

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.final_weight'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 0, 2, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [1, 0, 2, 0] },
        { content: '', background_color: '8DB4E2', border_width: [1, 1, 2, 0] },
        {
          content: "<b>#{annual_weight}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [1, 1, 2, 1]
        }
      ]

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.final_qualification'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [2, 0, 2, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [2, 0, 2, 0] },
        { content: '', background_color: '8DB4E2', border_width: [2, 1, 2, 0] },
        {
          content: "<b>#{annual_qualification}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [2, 1, 2, 1]
        }
      ]

      pdf.table table, column_widths: [110, 110, 110, 110]

      pdf.move_down PDF_FONT_SIZE * 3

      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.detailed_report.conclusions_title'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.detailed_report.conclusions_body',
                      calification: annual_qualification),
               inline_format: true,
               align: :justify
    end

    def put_nbc_comparision_to_previous_period pdf, period, previous_period, results_period_with_final_weaknesses, results_previous_period_with_final_weaknesses
      pdf.move_down PDF_FONT_SIZE * 3

      pdf.text I18n.t('conclusion_committee_report.nbc_internal_control_qualification_as_group_of_companies_report.comparision_to_previous_period.classification_title',
                      period: previous_period.name),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE * 2

      total_cycles_period          = 0
      total_weight_period          = 0
      total_cycles_previous_period = 0
      total_weight_previous_period = 0
      table                        = []

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_cycle'),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_internal_control_qualification_as_group_of_companies_report.comparision_to_previous_period.header_weight',
                          period: period.name),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_qualification'),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_cycle'),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_internal_control_qualification_as_group_of_companies_report.comparision_to_previous_period.header_weight',
                          period: previous_period.name),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_qualification'),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        }
      ]

      max_elements =
        if results_period_with_final_weaknesses.count > results_previous_period_with_final_weaknesses.count
          results_period_with_final_weaknesses.count
        else
          results_previous_period_with_final_weaknesses.count
        end

      for i in 0...max_elements
        array_to_table = []

        if results_period_with_final_weaknesses[i].present?
          total_cycles_period += 1
          total_weight_period += results_period_with_final_weaknesses[i][:total_weight]

          array_to_table << [
            { content: results_period_with_final_weaknesses[i][:name], size: 8 },
            { content: results_period_with_final_weaknesses[i][:count].to_s, align: :center, size: 8 },
            { content: results_period_with_final_weaknesses[i][:qualification].to_s, align: :center, size: 8 }
          ]
        else
          array_to_table << [
            { content: '', border_width: [1, 0, 1, 1] },
            { content: '', border_width: [1, 0, 1, 0] },
            { content: '', border_width: [1, 1, 1, 0] }
          ]
        end

        if results_previous_period_with_final_weaknesses[i].present?
          total_cycles_previous_period += 1
          total_weight_previous_period += results_previous_period_with_final_weaknesses[i][:total_weight]

          array_to_table << [
            { content: results_previous_period_with_final_weaknesses[i][:name], size: 8 },
            { content: results_previous_period_with_final_weaknesses[i][:count].to_s, align: :center, size: 8 },
            { content: results_previous_period_with_final_weaknesses[i][:qualification].to_s, align: :center, size: 8 }
          ]
        else
          array_to_table << [
            { content: '', border_width: [1, 0, 1, 1] },
            { content: '', border_width: [1, 0, 1, 0] },
            { content: '', border_width: [1, 1, 1, 0] }
          ]
        end

        table << array_to_table.flatten
      end

      table << [
        { content: '', border_width: [2, 0, 2, 1] },
        { content: '', border_width: [2, 0, 2, 0] },
        { content: '', border_width: [2, 1, 2, 0] },
        { content: '', border_width: [2, 0, 2, 1] },
        { content: '', border_width: [2, 0, 2, 0] },
        { content: '', border_width: [2, 1, 2, 0] }
      ]

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.count_weight'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [2, 0, 1, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [2, 1, 1, 0] },
        {
          content: "<b>#{total_weight_period}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [2, 1, 1, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.count_weight'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [2, 0, 1, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [2, 1, 1, 0] },
        {
          content: "<b>#{total_weight_previous_period}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [2, 1, 1, 1]
        }
      ]

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.count_cycles'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 0, 1, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [1, 1, 1, 0] },
        {
          content: "<b>#{total_cycles_period}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [1, 1, 1, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.count_cycles'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 0, 1, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [1, 1, 1, 0] },
        {
          content: "<b>#{total_cycles_previous_period}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [1, 1, 1, 1]
        }
      ]

      annual_weight_period          = (total_weight_period / (total_cycles_period.zero? ? 1 : total_cycles_period.to_f)).round
      annual_weight_previous_period = (total_weight_previous_period / (total_cycles_previous_period.zero? ? 1 : total_cycles_previous_period.to_f)).round

      annual_qualification_period          = calculate_qualification annual_weight_period
      annual_qualification_previous_period = calculate_qualification annual_weight_previous_period

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.final_weight'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 0, 2, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [1, 1, 2, 0] },
        {
          content: "<b>#{annual_weight_period}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.final_weight'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 0, 2, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [1, 1, 2, 0] },
        {
          content: "<b>#{annual_weight_previous_period}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [1, 1, 2, 1]
        }
      ]

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.final_qualification'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [2, 0, 2, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [2, 1, 2, 0] },
        {
          content: "<b>#{annual_qualification_period}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [2, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.final_qualification'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [2, 0, 2, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [2, 1, 2, 0] },
        {
          content: "<b>#{annual_qualification_previous_period}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [2, 1, 2, 1]
        }
      ]

      pdf.table table, column_widths: [80, 70, 80, 80, 70, 80]

      pdf.move_down PDF_FONT_SIZE * 3

      pdf.text I18n.t('conclusion_committee_report.nbc_internal_control_qualification_as_group_of_companies_report.comments'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_committee_report.nbc_internal_control_qualification_as_group_of_companies_report.comparision_to_previous_period.conclusions_body',
                      annual_qualification_period: annual_qualification_period,
                      annual_weight_period: annual_weight_period,
                      annual_weight_previous_period: annual_weight_previous_period),
               inline_format: true,
               align: :justify
    end

    def put_nbc_comparision_to_actual_situation pdf, period, results_period_with_final_weaknesses, results_period_with_not_final_weaknesses
      pdf.move_down PDF_FONT_SIZE * 3

      date = Date.today

      pdf.text I18n.t('conclusion_committee_report.nbc_internal_control_qualification_as_group_of_companies_report.comparision_to_actual_situation.classification_title',
                      date: l(date, format: :minimal)),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE * 2

      total_cycles                  = 0
      total_weight                  = 0
      total_cycles_actual_situation = 0
      total_weight_actual_situation = 0
      table                         = []

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_cycle'),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_weight',
                          period: period.name),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_qualification'),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_cycle'),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_internal_control_qualification_as_group_of_companies_report.comparision_to_actual_situation.actual_qualification',
                          date: l(date, format: :minimal)),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_qualification'),
          align: :center,
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 1, 2, 1]
        },
        {
          content: '', border_width: [0, 0, 0, 0]
        }
      ]

      max_elements =
        if results_period_with_final_weaknesses.count > results_period_with_not_final_weaknesses.count
          results_period_with_final_weaknesses.count
        else
          results_period_with_not_final_weaknesses.count
        end

      for i in 0...max_elements
        array_to_table = []

        if results_period_with_final_weaknesses[i].present?
          total_cycles += 1
          total_weight += results_period_with_final_weaknesses[i][:total_weight]

          array_to_table << [
            { content: results_period_with_final_weaknesses[i][:name], size: 8 },
            { content: results_period_with_final_weaknesses[i][:count].to_s, align: :center, size: 8 },
            { content: results_period_with_final_weaknesses[i][:qualification].to_s, align: :center, size: 8 }
          ]
        else
          array_to_table << [
            { content: '', border_width: [1, 0, 1, 1] },
            { content: '', border_width: [1, 0, 1, 0] },
            { content: '', border_width: [1, 1, 1, 0] }
          ]
        end

        if results_period_with_not_final_weaknesses[i].present?
          total_cycles_actual_situation += 1
          total_weight_actual_situation += results_period_with_not_final_weaknesses[i][:total_weight]

          array_to_table << [
            { content: results_period_with_not_final_weaknesses[i][:name], size: 8 },
            { content: results_period_with_not_final_weaknesses[i][:count].to_s, align: :center, size: 8 },
            { content: results_period_with_not_final_weaknesses[i][:qualification].to_s, align: :center, size: 8 }
          ]
        else
          array_to_table << [
            { content: '', border_width: [1, 0, 1, 1] },
            { content: '', border_width: [1, 0, 1, 0] },
            { content: '', border_width: [1, 1, 1, 0] }
          ]
        end

        array_to_table << [
          { content: '', border_width: [0, 0, 0, 0] }
        ]

        table << array_to_table.flatten
      end

      table << [
        { content: '', border_width: [2, 0, 2, 1] },
        { content: '', border_width: [2, 0, 2, 0] },
        { content: '', border_width: [2, 1, 2, 0] },
        { content: '', border_width: [2, 0, 2, 1] },
        { content: '', border_width: [2, 0, 2, 0] },
        { content: '', border_width: [2, 1, 2, 0] },
        { content: '', border_width: [0, 0, 0, 0] }
      ]

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.count_weight'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [2, 0, 1, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [2, 1, 1, 0] },
        {
          content: "<b>#{total_weight}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [2, 1, 1, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.count_weight'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [2, 0, 1, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [2, 1, 1, 0] },
        {
          content: "<b>#{total_weight_actual_situation}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [2, 1, 1, 1]
        },
        { content: '', border_width: [0, 0, 0, 0] }
      ]

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.count_cycles'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 0, 1, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [1, 0, 1, 0] },
        {
          content: "<b>#{total_cycles}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [1, 1, 1, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.count_cycles'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 0, 1, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [1, 0, 1, 0] },
        {
          content: "<b>#{total_cycles_actual_situation}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [1, 1, 1, 1]
        },
        { content: '', border_width: [0, 0, 0, 0] }
      ]

      annual_weight                  = (total_weight / (total_cycles.zero? ? 1 : total_cycles.to_f)).round
      annual_weight_actual_situation = (total_weight_actual_situation / (total_cycles_actual_situation.zero? ? 1 : total_cycles_actual_situation.to_f)).round

      annual_qualification                  = calculate_qualification annual_weight
      annual_qualification_actual_situation = calculate_qualification annual_weight_actual_situation

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.final_weight'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 0, 2, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [1, 1, 2, 0] },
        {
          content: "<b>#{annual_weight}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [1, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.final_weight'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [1, 0, 2, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [1, 1, 2, 0] },
        {
          content: "<b>#{annual_weight_actual_situation}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [1, 1, 2, 1]
        },
        { content: '', border_width: [0, 0, 0, 0] }
      ]

      table << [
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.final_qualification'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [2, 0, 2, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [2, 1, 2, 0] },
        {
          content: "<b>#{annual_qualification}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [2, 1, 2, 1]
        },
        {
          content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.final_qualification'),
          size: 8,
          inline_format: true,
          background_color: '8DB4E2',
          border_width: [2, 0, 2, 1]
        },
        { content: '', background_color: '8DB4E2', border_width: [2, 1, 2, 0] },
        {
          content: "<b>#{annual_qualification_actual_situation}</b>",
          size: 8,
          inline_format: true,
          align: :center,
          border_width: [2, 1, 2, 1]
        },
        {
          content: "<b>Sin cambios</b>",
          size: 6,
          inline_format: true,
          align: :center,
          border_width: [2, 1, 2, 1]
        }
      ]

      pdf.table table, column_widths: [73, 63, 73, 73, 63, 73, 40]

      pdf.move_down PDF_FONT_SIZE * 3

      pdf.text I18n.t('conclusion_committee_report.nbc_internal_control_qualification_as_group_of_companies_report.comments'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_committee_report.nbc_internal_control_qualification_as_group_of_companies_report.comparision_to_previous_period.conclusions_body',
                      annual_qualification_period: annual_qualification,
                      annual_weight_period: annual_weight,
                      annual_weight_previous_period: annual_weight_actual_situation),
               inline_format: true,
               align: :justify
    end
end
