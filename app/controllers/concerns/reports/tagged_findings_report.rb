module Reports::TaggedFindingsReport
  extend ActiveSupport::Concern

  included do
    before_action :set_tagged_findings_for_report, only: [:tagged_findings_report, :create_tagged_findings_report]
  end

  def tagged_findings_report
    @title = t '.title'
    @columns = tagged_findings_column_order.keys

    respond_to do |format|
      format.html
      format.csv do
        render csv: tagged_findings_report_csv, filename: @title.downcase
      end
    end
  end

  def create_tagged_findings_report
    pdf_id = rand 1_000_000
    pdf    = init_pdf params[:report_title], params[:report_subtitle]

    add_tagged_findings_filter_options_to_pdf pdf
    add_tagged_findings_count_to_pdf pdf
    add_tagged_findings_report_to_pdf pdf

    full_path    = pdf.custom_save_as tagged_findings_report_pdf_name, 'tagged_findings_report', pdf_id
    @report_path = full_path.sub Rails.root.to_s, ''

    respond_to do |format|
      format.html { redirect_to @report_path }
      format.js   { render 'shared/pdf_report' }
    end
  end

  private

    def set_tagged_findings_for_report
      report_params = params[:tagged_findings_report]

      @findings = if report_params.present?
                    @filters = []
                    scope = filter_tagged_findings_report_by_status(
                      scoped_tagged_findings,
                      report_params
                    )

                    findings_with_less_than_n_tags scope, report_params
                  else
                    Finding.none
                  end
    end

    def filter_tagged_findings_report_by_status scope, report_params
      states = report_params[:finding_status]&.reject(&:blank?) || []

      return scope if states.empty?

      not_muted_states     = Finding::EXCLUDE_FROM_REPORTS_STATUS + [:implemented_audited]
      mute_state_filter_on = Finding::STATUS.except(*not_muted_states).values.map(&:to_s)

      unless states.sort == mute_state_filter_on.sort
        state_text = states.map do |s|
          t "findings.state.#{Finding::STATUS.invert[s.to_i]}"
        end

        @filters << "<b>#{Finding.human_attribute_name('state')}</b> = \"#{state_text.to_sentence}\""
      end

      scope.where state: states
    end

    def findings_with_less_than_n_tags scope, report_params
      n = report_params[:tags_count].to_i
      @filters << "<b> #{t(tagged_findings_translation_key + '.tags_count_label')}</b> = #{n}"

      count_less_than = "COUNT(#{Tag.quoted_table_name}.#{Tag.qcn 'id'}) < ?"

      @ids_with_count = scope
        .finals(false)
        .includes(:tags).group(:id).having(count_less_than, n)
        .unscope(:order)  # list_with/without_final_review
        .count "#{Tag.quoted_table_name}.#{Tag.qcn 'id'}"

      scope.where(id: @ids_with_count.keys).preload(
        :organization, :review, :business_unit_type,
        :users_that_can_act_as_auditor
      )
    end

    def scoped_tagged_findings
      if controller_name == 'execution_reports'
        Finding.list_without_final_review
      else
        Finding.list_with_final_review
      end
    end

    def tagged_findings_translation_key
      [controller_name, 'tagged_findings_report'].join('.')
    end

    def tagged_findings_report_pdf_name
      t "#{tagged_findings_translation_key}.pdf_name"
    end

    def add_tagged_findings_count_to_pdf pdf
      pdf.text I18n.t(
        "#{tagged_findings_translation_key}.findings_count",
        count: @findings.count
      )

      pdf.move_down PDF_FONT_SIZE
    end

    def tagged_findings_report_rows
      @findings.map do |finding|
        [
          finding.organization.prefix,
          finding.review.identification,
          finding.business_unit_type.name,
          finding.review_code,
          finding.title,
          finding.state_text,
          finding.users_that_can_act_as_auditor.map(&:full_name).join('; '),
          @ids_with_count[finding.id]
        ]
      end
    end

    def add_tagged_findings_report_to_pdf pdf
      column_data = tagged_findings_report_rows
      table_options = pdf.default_table_options tagged_findings_column_widths(pdf)

      pdf.table column_data.insert(0, tagged_findings_column_order.keys), table_options do
        row(0).style(
          background_color: 'cccccc',
          padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
        )
      end
    end

    def add_tagged_findings_filter_options_to_pdf pdf
      add_pdf_filters pdf, 'follow_up', @filters
    end

    def tagged_findings_column_order
      @tagged_findings_columns_order ||= {
        Organization.model_name.human               => 10,
        Review.model_name.human                     => 9,
        BusinessUnitType.model_name.human           => 14,
        Finding.human_attribute_name('review_code') => 7,
        Finding.human_attribute_name('title')       => 30,
        Finding.human_attribute_name('state')       => 13,
        t('finding.auditors', count: 0)             => 10,
        Tag.model_name.human(count: 0)              => 8
      }
    end

    def tagged_findings_column_widths pdf
      tagged_findings_column_order.values.map do |col_width|
        pdf.percent_width col_width
      end
    end

    def tagged_findings_report_csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = ::CSV.generate(options) do |csv|
        csv << tagged_findings_column_order.keys

        tagged_findings_report_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end
end
