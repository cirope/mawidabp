module Reports::TaggedFindingsReport
  extend ActiveSupport::Concern

  included do
    before_action :set_tagged_findings_for_report, only: [:tagged_findings_report, :create_tagged_findings_report]
  end

  def tagged_findings_report
    @title = t '.title'
    @columns = tagged_findings_column_order.keys

    render 'findings/tagged_findings_report'
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
                    findings_with_less_than_n_tags report_params[:tags_count].to_i
                  else
                    Finding.none
                  end
    end

    def findings_with_less_than_n_tags n
      count_less_than = "COUNT(#{Tag.quoted_table_name}.#{Tag.qcn 'id'}) < ?"

      @ids_with_count = scoped_tagged_findings
        .finals(false)
        .includes(:tags).group(:id).having(count_less_than, n)
        .unscope(:order)  # list_with/without_final_review
        .count "#{Tag.quoted_table_name}.#{Tag.qcn 'id'}"

      scoped_tagged_findings.where(id: @ids_with_count.keys).preload(
          :organization, :review, :business_unit_type,
          :users_that_can_act_as_audited
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

    def add_tagged_findings_report_to_pdf pdf
      column_data = @findings.map do |finding|
        [
          finding.organization.prefix,
          finding.review.identification,
          finding.business_unit_type.name,
          finding.review_code,
          finding.title,
          finding.state_text,
          finding.users_that_can_act_as_audited.map(&:full_name).join('; '),
          @ids_with_count[finding.id]
        ]
      end

      table_options = pdf.default_table_options tagged_findings_column_widths(pdf)

      pdf.table column_data.insert(0, tagged_findings_column_order.keys), table_options do
        row(0).style(
          background_color: 'cccccc',
          padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
        )
      end
    end

    def add_tagged_findings_filter_options_to_pdf pdf
      filters = [
        [
          '<b>' + t("#{tagged_findings_translation_key}.tags_count_label") + '</b>',
          params[:tagged_findings_report][:tags_count]
        ].join(' ')
      ]

      add_pdf_filters pdf, 'follow_up', filters
    end

    def tagged_findings_column_order
      @tagged_findings_columns_order ||= {
        Organization.model_name.human => 10,
        Review.model_name.human => 9,
        BusinessUnitType.model_name.human => 9,
        Finding.human_attribute_name(:review_code) => 7,
        Finding.human_attribute_name(:title) => 40,
        Finding.human_attribute_name(:state) => 8,
        Finding.human_attribute_name(:auditors) => 10,
        Tag.model_name.human(count: 0) => 8
      }
    end

    def tagged_findings_column_widths pdf
      tagged_findings_column_order.values.map do |col_width|
        pdf.percent_width col_width
      end
    end
end
