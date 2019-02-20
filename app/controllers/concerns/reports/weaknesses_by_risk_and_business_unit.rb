module Reports::WeaknessesByRiskAndBusinessUnit
  extend ActiveSupport::Concern

  include Reports::PDF
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

    if @weaknesses_by_business_unit_types.size > 1
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
      @filters = []
      final = params[:final] == 'true'
      exclude = %i(confirmed unconfirmed unanswered notify incomplete)
      states = Finding::STATUS.except(*exclude).values & Finding::PENDING_STATUS
      between = [
        t('shared.filters.date_field.between').downcase,
        [l(@from_date), l(@to_date)].to_sentence
      ].join ' '
      weaknesses = Weakness.
        finals(final).
        list_with_final_review.
        where(state: states).
        includes(:business_unit, :business_unit_type, review: :conclusion_final_review)

      if params[:weaknesses_by_risk_and_business_unit]
        weaknesses = filter_weaknesses_by_risk_and_business_unit_by_date   weaknesses, between
        weaknesses = filter_weaknesses_by_risk_and_business_unit_by_status weaknesses
      else
        weaknesses = weaknesses.by_issue_date 'BETWEEN', @from_date, @to_date

        @filters << [
          "<b>#{ConclusionFinalReview.human_attribute_name 'issue_date'}</b>",
          between
        ].join(' ')
      end

      @weaknesses_by_business_unit_types = weaknesses_by_risk_and_business_unit_table weaknesses
    end

    def weaknesses_by_risk_and_business_unit_table weaknesses
      result = {
        total_by_risk: Hash[Weakness.risks.keys.map { |r| [r, 0] }]
      }

      weaknesses.find_each do |weakness|
        but_name = weakness.business_unit_type.name
        bu_name  = weakness.business_unit.name
        risk     = Weakness.risks.invert[weakness.risk]

        result[but_name]          ||= {}
        result[but_name][bu_name] ||= Hash[Weakness.risks.keys.map { |r| [r, 0] }]

        result[but_name][bu_name][:total] ||= 0
        result[:total_by_risk][:total]    ||= 0

        result[:total_by_risk][risk]      += 1
        result[:total_by_risk][:total]    += 1
        result[but_name][bu_name][risk]   += 1
        result[but_name][bu_name][:total] += 1
      end

      result
    end

    def filter_weaknesses_by_risk_and_business_unit_by_date weaknesses, between
      if params[:weaknesses_by_risk_and_business_unit][:date_field] == 'origination_date'
        @filters << [
          "<b>#{Weakness.human_attribute_name 'origination_date'}</b>",
          between
        ].join(' ')

        weaknesses.by_origination_date @from_date, @to_date
      else
        @filters << [
          "<b>#{ConclusionFinalReview.human_attribute_name 'issue_date'}</b>",
          between
        ].join(' ')

        weaknesses.by_issue_date 'BETWEEN', @from_date, @to_date
      end
    end

    def filter_weaknesses_by_risk_and_business_unit_by_status weaknesses
      states               = Array(params[:weaknesses_by_risk_and_business_unit][:finding_status]).reject(&:blank?)
      not_muted_states     = Finding::EXCLUDE_FROM_REPORTS_STATUS + [:implemented_audited]
      mute_state_filter_on = Finding::STATUS.except(*not_muted_states).map do |k, v|
        v.to_s
      end

      if states.present?
        unless states.sort == mute_state_filter_on.sort
          state_text = states.map do |s|
            t "findings.state.#{Finding::STATUS.invert[s.to_i]}"
          end

          @filters << "<b>#{Finding.human_attribute_name('state')}</b> = \"#{state_text.to_sentence}\""
        end

        weaknesses.where state: states
      else
        weaknesses
      end
    end

    def put_weaknesses_by_risk_and_business_unit_on pdf
      widths        = [20, 52, 7, 7, 7, 7].map { |w| pdf.percent_width w }
      table_options = pdf.default_table_options widths

      pdf.table(weaknesses_by_risk_and_business_unit_pdf_data, table_options) do
        header_style = {
          background_color: 'cccccc',
          padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
        }

        row(0).style header_style
        row(1).style header_style
      end
    end

    def weaknesses_by_risk_and_business_unit_pdf_data
      [
        [
          {
            content: BusinessUnitType.model_name.human,
            rowspan: 2
          },
          {
            content: BusinessUnit.model_name.human,
            rowspan: 2
          },
          {
            content: Weakness.human_attribute_name('risk'),
            colspan: Weakness.risks.size + 1,
            align:   :center
          }
        ],
        Weakness.risks.keys.map do |risk_type|
          {
            content: t("risk_types.#{risk_type}"),
            align:   :right
          }
        end.concat([
          {
            content: t("#{@controller}_committee_report.weaknesses_by_risk_and_business_unit.total"),
            align:   :right
          }
        ]),
      ].concat(
        weaknesses_by_risk_and_business_unit_pdf_rows
      )
    end

    def weaknesses_by_risk_and_business_unit_pdf_rows
      rows      = []
      but_names = @weaknesses_by_business_unit_types.keys.reject do |e|
        e.kind_of? Symbol
      end

      but_names.sort.each do |but_name|
        business_units = @weaknesses_by_business_unit_types[but_name]

        business_units.keys.sort.each_with_index do |bu_name, i|
          row         = []
          risk_counts = business_units[bu_name]

          if i == 0
            row << {
              content: but_name,
              rowspan: business_units.size
            }
          end

          row << bu_name

          Weakness.risks.keys.each do |risk_type|
            row << {
              content: risk_counts[risk_type].to_s,
              align:   :right
            }
          end

          row << {
            content: "<b>#{risk_counts[:total]}</b>",
            align:   :right
          }

          rows << row
        end
      end

      rows << weaknesses_by_risk_and_business_unit_pdf_total_row
    end

    def weaknesses_by_risk_and_business_unit_pdf_total_row
      [
        {
          content: "<b>#{t 'follow_up_committee_report.weaknesses_by_risk_and_business_unit.total'}",
          colspan: 2
        }
      ].concat(
        Weakness.risks.keys.map do |risk_type|
          {
            content: "<b>#{@weaknesses_by_business_unit_types[:total_by_risk][risk_type]}</b>",
            align:   :right
          }
        end
      ).concat([
        content: "<b>#{@weaknesses_by_business_unit_types[:total_by_risk][:total]}</b>",
        align:   :right
      ])
    end
end
