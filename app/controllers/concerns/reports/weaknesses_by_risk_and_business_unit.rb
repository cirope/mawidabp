module Reports::WeaknessesByRiskAndBusinessUnit
  extend ActiveSupport::Concern

  include Reports::Pdf
  include Reports::Period

  def weaknesses_by_risk_and_business_unit
    init_weaknesses_by_risk_and_business_unit_vars

    respond_to do |format|
      format.html
    end
  end

  def create_weaknesses_by_risk_and_business_unit
    init_weaknesses_by_risk_and_business_unit_vars

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    if @weaknesses_by_business_unit_types.first.size > 1
      put_weaknesses_by_risk_and_business_unit_on pdf
    else
      pdf.move_down PDF_FONT_SIZE
      pdf.text(
        t("#{@controller}_committee_report.weaknesses_by_risk_and_business_unit.empty"),
        style: :italic
      )
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_by_risk_and_business_unit')

    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_by_risk_and_business_unit')
  end

  private

    def init_weaknesses_by_risk_and_business_unit_vars
      @controller = params[:controller_name]
      @title = t "#{@controller}_committee_report.weaknesses_by_risk_and_business_unit_title"
      @from_date, @to_date = *make_date_range(params[:weaknesses_by_risk_and_business_unit])
      @mid_date = mid_date params[:weaknesses_by_risk_and_business_unit]
      @filters = []
      @business_unit_type_names = []
      @unit_names = {}
      between = [
        t('shared.filters.date_field.between').downcase,
        [l(@from_date), l(@to_date)].to_sentence
      ].join ' '
      weaknesses = Weakness.
        list_for_report.
        or(Weakness.list_without_final_review.with_repeated).
        finals(false).
        includes :business_unit, :business_unit_type, review: :conclusion_final_review

      if params[:weaknesses_by_risk_and_business_unit]
        weaknesses = filter_weaknesses_by_risk_and_business_unit_by_icon weaknesses
      end

      @weaknesses_by_business_unit_types =
        weaknesses_by_risk_and_business_unit_types weaknesses
    end

    def filter_weaknesses_by_risk_and_business_unit_by_icon weaknesses
      if @icon = params[:weaknesses_by_risk_and_business_unit][:icon].presence
        weaknesses.by_tag_icon @icon
      else
        weaknesses
      end
    end

    def weaknesses_by_risk_and_business_unit_types weaknesses
      exclude        = %i(confirmed unconfirmed unanswered notify incomplete)
      pending_states = Finding::STATUS.except(*exclude).values & Finding::PENDING_STATUS

      weaknesses_1a = weaknesses_by_risk_and_business_unit_types_1a weaknesses, pending_states
      weaknesses_1b = weaknesses_by_risk_and_business_unit_types_1b weaknesses
      weaknesses_2  = weaknesses_by_risk_and_business_unit_types_2  weaknesses
      weaknesses_4a = weaknesses_by_risk_and_business_unit_types_4a weaknesses, pending_states
      weaknesses_4b = weaknesses_by_risk_and_business_unit_types_4b weaknesses

      weaknesses_1_table = weaknesses_by_risk_and_business_unit_table weaknesses_1a, weaknesses_1b
      weaknesses_2_table = weaknesses_by_risk_and_business_unit_table weaknesses_2
      weaknesses_4_table = weaknesses_by_risk_and_business_unit_table weaknesses_4a, weaknesses_4b
      weaknesses_3_table = weaknesses_by_risk_and_business_unit_table_3 weaknesses_1_table,
                                                                        weaknesses_2_table,
                                                                        weaknesses_4_table

      [
        weaknesses_1_table,
        weaknesses_2_table,
        weaknesses_3_table,
        weaknesses_4_table
      ]
    end

    def weaknesses_by_risk_and_business_unit_types_1a weaknesses, pending_states
      weaknesses.
        where(state: pending_states).
        by_origination_date 'BETWEEN', @from_date, @mid_date
    end

    def weaknesses_by_risk_and_business_unit_types_1b weaknesses
      weaknesses.
        where(state: Finding::STATUS[:implemented_audited]).
        where(solution_date: (@mid_date + 1.day)..Time.zone.today).
        by_origination_date 'BETWEEN', @from_date, @mid_date
    end

    def weaknesses_by_risk_and_business_unit_types_2 weaknesses
      weaknesses.
        not_repeated.
        by_origination_date 'BETWEEN', @mid_date, @to_date
    end

    def weaknesses_by_risk_and_business_unit_types_4a weaknesses, pending_states
      weaknesses.
        where(state: pending_states).
        by_origination_date 'BETWEEN', @from_date, @to_date
    end

    def weaknesses_by_risk_and_business_unit_types_4b weaknesses
      weaknesses.
        where(state: Finding::STATUS[:implemented_audited]).
        by_origination_date('BETWEEN', @from_date, @to_date).
        where solution_date: @to_date..Time.zone.today
    end

    def weaknesses_by_risk_and_business_unit_table_3 weaknesses_1_table,
                                                     weaknesses_2_table,
                                                     weaknesses_4_table
      result = { total_by_risk: {} }

      @business_unit_type_names.sort.each do |but_name|
        result[but_name] ||= {}

        @unit_names[but_name].sort.each do |unit_name|
          result[but_name][unit_name] ||= {}

          business_units_1 = weaknesses_1_table[but_name] || {}
          business_units_2 = weaknesses_2_table[but_name] || {}
          business_units_4 = weaknesses_4_table[but_name] || {}
          risk_counts_1 = business_units_1[unit_name] || Hash.new(0)
          risk_counts_2 = business_units_2[unit_name] || Hash.new(0)
          risk_counts_4 = business_units_4[unit_name] || Hash.new(0)

          Weakness.risks.keys.each do |risk_type|
            result[but_name][unit_name][risk_type] = risk_counts_1[risk_type] +
                                                     risk_counts_2[risk_type] -
                                                     risk_counts_4[risk_type]
          end

          result[but_name][unit_name][:total] = risk_counts_1[:total] +
                                                risk_counts_2[:total] -
                                                risk_counts_4[:total]
        end
      end

      Weakness.risks.keys.each do |risk_type|
        result[:total_by_risk][risk_type] = weaknesses_1_table[:total_by_risk][risk_type] +
                                            weaknesses_2_table[:total_by_risk][risk_type] -
                                            weaknesses_4_table[:total_by_risk][risk_type]
      end

      result[:total_by_risk][:total] = weaknesses_1_table[:total_by_risk][:total] +
                                       weaknesses_2_table[:total_by_risk][:total] -
                                       weaknesses_4_table[:total_by_risk][:total]

      result
    end

    def weaknesses_by_risk_and_business_unit_table *weaknesses_scopes
      result = {
        total_by_risk: Hash[Weakness.risks.keys.map { |r| [r, 0] }]
      }

      result[:total_by_risk][:total] = 0

      weaknesses_scopes.each do |weaknesses|
        weaknesses.find_each do |weakness|
          but_name  = @icon ? 'Main' : weakness.business_unit_type.name
          risk      = Weakness.risks.invert[weakness.risk]
          unit_name = if @icon
                        weakness.taggings.detect { |t| t.tag.icon == @icon }.tag.name
                      else
                        weakness.business_unit.name
                      end

          if @business_unit_type_names.exclude? but_name
            @business_unit_type_names << but_name
          end

          @unit_names[but_name] ||= []

          if @unit_names[but_name].exclude? unit_name
            @unit_names[but_name] << unit_name
          end

          result[but_name]            ||= {}
          result[but_name][unit_name] ||= Hash[Weakness.risks.keys.map { |r| [r, 0] }]

          result[but_name][unit_name][:total] ||= 0

          result[:total_by_risk][risk]        += 1
          result[:total_by_risk][:total]      += 1
          result[but_name][unit_name][risk]   += 1
          result[but_name][unit_name][:total] += 1
        end
      end

      result
    end

    def put_weaknesses_by_risk_and_business_unit_on pdf
      risk_size     = Weakness.risks.size.next * @weaknesses_by_business_unit_types.size
      risk_width    = 65.0
      risk_widths   = risk_size.times.map { risk_width / risk_size }
      widths        = @icon ? [100 - risk_width] : [15, 85 - risk_width]
      widths        = widths.concat(risk_widths).map do |w|
        pdf.percent_width w
      end
      table_options = pdf.default_table_options(widths).merge header: 3

      pdf.font_size PDF_FONT_SIZE * 0.65 do
        pdf.table(weaknesses_by_risk_and_business_unit_pdf_data, table_options) do
          header_style = {
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          }

          row(0).style header_style
          row(1).style header_style
          row(2).style header_style
        end
      end
    end

    def weaknesses_by_risk_and_business_unit_pdf_data
      [
        [
          ({
            content: BusinessUnitType.model_name.human,
            rowspan: 3
          } unless @icon),
          {
            content: @icon ? Tag.model_name.human : BusinessUnit.model_name.human,
            rowspan: 3
          },
          {
            content: t(
              "#{@controller}_committee_report.weaknesses_by_risk_and_business_unit.being_implemented",
              date: l(@mid_date, format: :minimal)
            ),
            colspan: Weakness.risks.size.next,
            align:   :center
          },
          {
            content: t(
              "#{@controller}_committee_report.weaknesses_by_risk_and_business_unit.created",
              from_date: l(@mid_date, format: :minimal),
              to_date: l(@to_date, format: :minimal)
            ),
            colspan: Weakness.risks.size.next,
            align:   :center
          },
          {
            content: t(
              "#{@controller}_committee_report.weaknesses_by_risk_and_business_unit.implemented",
              from_date: l(@mid_date, format: :minimal),
              to_date: l(@to_date, format: :minimal)
            ),
            colspan: Weakness.risks.size.next,
            align:   :center
          },
          {
            content: t(
              "#{@controller}_committee_report.weaknesses_by_risk_and_business_unit.being_implemented",
              date: l(@to_date, format: :minimal)
            ),
            colspan: Weakness.risks.size.next,
            align:   :center
          }
        ].compact,
        @weaknesses_by_business_unit_types.size.times.map do
          [
            {
              content: Weakness.human_attribute_name('risk'),
              colspan: Weakness.risks.size,
              align:   :center
            },
            {
              content: t("#{@controller}_committee_report.weaknesses_by_risk_and_business_unit.total"),
              rowspan: 2,
              align:   :center
            }
          ]
        end.flatten,
        @weaknesses_by_business_unit_types.size.times.map do
          Weakness.risks.keys.reverse.map do |risk_type|
            {
              content: t("risk_types.#{risk_type}"),
              align:   :center
            }
          end
        end.flatten
      ].concat(
        weaknesses_by_risk_and_business_unit_pdf_rows
      )
    end

    def weaknesses_by_risk_and_business_unit_pdf_rows
      rows = []

      @business_unit_type_names.sort.map do |but_name|
        @unit_names[but_name].sort.each_with_index do |unit_name, i|
          row = []

          if i == 0 && @icon.blank?
            row << {
              content: but_name,
              rowspan: @unit_names[but_name].size
            }
          end

          row << unit_name

          @weaknesses_by_business_unit_types.each do |weaknesses_by_business_unit_types|
            business_units = weaknesses_by_business_unit_types[but_name] || {}
            risk_counts    = business_units[unit_name] || Hash.new(0)

            Weakness.risks.keys.reverse.each do |risk_type|
              row << {
                content: risk_counts[risk_type].to_s,
                align:   :center
              }
            end

            row << {
              content: "<b>#{risk_counts[:total]}</b>",
              align:   :center
            }
          end

          rows << row
        end
      end

      rows << weaknesses_by_risk_and_business_unit_pdf_total_row
    end

    def weaknesses_by_risk_and_business_unit_pdf_total_row
      [
        {
          content: "<b>#{t 'follow_up_committee_report.weaknesses_by_risk_and_business_unit.total'}",
          colspan: @icon ? 1 : 2
        }
      ].concat(
        @weaknesses_by_business_unit_types.map do |weaknesses_by_business_unit_types|
          Weakness.risks.keys.reverse.map do |risk_type|
            {
              content: "<b>#{weaknesses_by_business_unit_types[:total_by_risk][risk_type]}</b>",
              align:   :center
            }
          end.concat([
            content: "<b>#{weaknesses_by_business_unit_types[:total_by_risk][:total]}</b>",
            align:   :center
          ])
        end.flatten
      )
    end

    def mid_date parameters
      if parameters
        mid_date = Timeliness.parse parameters[:mid_date], :date
      end

      mid_date&.to_date || Time.zone.today.at_beginning_of_month + 15.days
    end
end
