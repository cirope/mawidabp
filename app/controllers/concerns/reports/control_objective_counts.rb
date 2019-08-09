module Reports::ControlObjectiveCounts
  extend ActiveSupport::Concern

  include Reports::PDF
  include Reports::Period

  def control_objective_counts
    init_control_objective_counts_vars

    respond_to do |format|
      format.html
      format.csv do
        render csv: control_objective_counts_csv, filename: @title.downcase
      end
    end
  end

  def create_control_objective_counts
    init_control_objective_counts_vars

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    if @control_objective_items.any?
      @control_objective_items.each_with_index do |control_objective_item, index|
        title = [
          "<b>#{index + 1}</b>",
          "<i>#{BusinessUnit.model_name.human}:</i>",
          control_objective_item.business_unit
        ].join(' ')

        pdf.text title, size: PDF_FONT_SIZE, inline_format: true, align: :justify

        control_objective_counts_pdf_items(control_objective_item).each do |item|
          text = "<i>#{item.first}:</i> #{item.last.to_s.strip}"

          pdf.text text, size: PDF_FONT_SIZE, inline_format: true, align: :justify
        end

        pdf.move_down PDF_FONT_SIZE
      end
    else
      pdf.move_down PDF_FONT_SIZE
      pdf.text(
        t("#{@controller}_committee_report.control_objective_counts.without_control_objective_items"),
        style: :italic
      )
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'control_objective_counts')

    redirect_to_pdf(@controller, @from_date, @to_date, 'control_objective_counts')
  end

  private

    def init_control_objective_counts_vars
      @controller = params[:controller_name]
      @title = t("#{@controller}_committee_report.control_objective_counts_title")
      @from_date, @to_date = *make_date_range(params[:control_objective_counts])
      @filters = []
      order = [
        "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} ASC",
        "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'conclusion_index'} DESC",
        "#{Review.quoted_table_name}.#{Review.qcn 'identification'} ASC",
        "#{ControlObjectiveItem.quoted_table_name}.#{ControlObjectiveItem.qcn 'order_number'} ASC"
      ].map { |o| Arel.sql o }
      control_objective_items = ControlObjectiveItem.
        list_with_final_review.
        by_issue_date('BETWEEN', @from_date, @to_date).
        includes(:business_unit, :business_unit_type,
          review: [:plan_item, :conclusion_final_review]
        )

      if params[:control_objective_counts]
        control_objective_items = filter_control_objective_counts_by_business_unit_type control_objective_items
      end

      @control_objective_items = control_objective_items.reorder order
    end

    def control_objective_counts_csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = ::CSV.generate(options) do |csv|
        csv << control_objective_counts_csv_headers

        control_objective_counts_csv_data_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end

    def control_objective_counts_pdf_items control_objective_item
      [
        [
          PlanItem.human_attribute_name('project'),
          control_objective_item.review.plan_item.project
        ],
        [
          Review.model_name.human,
          control_objective_item.review.identification
        ],
        [
          BusinessUnitType.model_name.human,
          control_objective_item.business_unit_type
        ],
        [
          ConclusionFinalReview.human_attribute_name('issue_date'),
          l(control_objective_item.review.issue_date)
        ],
        [
          ControlObjectiveItem.human_attribute_name('control_objective_text'),
          control_objective_item.control_objective_text
        ],
        [
          ControlObjectiveItem.human_attribute_name('auditor_comment'),
          control_objective_item.auditor_comment
        ]
      ].concat(
        if ORGANIZATIONS_WITH_CONTROL_OBJECTIVE_COUNTS.include?(current_organization.prefix)
          [
            [
              ControlObjectiveItem.human_attribute_name('issues_count'),
              control_objective_item.issues_count
            ],
            [
              ControlObjectiveItem.human_attribute_name('alerts_count'),
              control_objective_item.alerts_count
            ]
          ]
        else
          []
        end
      ).compact
    end

    def filter_control_objective_counts_by_business_unit_type control_objective_items
      business_unit_types = Array(params[:control_objective_counts][:business_unit_type]).reject(&:blank?)

      if business_unit_types.present?
        selected_business_units = BusinessUnitType.list.where id: business_unit_types

        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{selected_business_units.pluck('name').to_sentence}\""

        control_objective_items.by_business_unit_type selected_business_units.ids
      else
        control_objective_items
      end
    end

    def control_objective_counts_csv_headers
      [
        BusinessUnit.model_name.human,
        PlanItem.human_attribute_name('project'),
        Review.model_name.human,
        BusinessUnitType.model_name.human,
        ConclusionFinalReview.human_attribute_name('issue_date'),
        ControlObjectiveItem.human_attribute_name('control_objective_text'),
        ControlObjectiveItem.human_attribute_name('auditor_comment')
      ].concat(
        if ORGANIZATIONS_WITH_CONTROL_OBJECTIVE_COUNTS.include?(current_organization.prefix)
          [
            ControlObjectiveItem.human_attribute_name('issues_count'),
            ControlObjectiveItem.human_attribute_name('alerts_count')
          ]
        else
          []
        end
      )
    end

    def control_objective_counts_csv_data_rows
      @control_objective_items.map do |control_objective_item|
        [
          control_objective_item.business_unit.to_s,
          control_objective_item.review.plan_item.project,
          control_objective_item.review.identification,
          control_objective_item.business_unit_type.to_s,
          l(control_objective_item.review.issue_date),
          control_objective_item.control_objective_text.to_s,
          control_objective_item.auditor_comment.to_s
        ].concat(
          if ORGANIZATIONS_WITH_CONTROL_OBJECTIVE_COUNTS.include?(current_organization.prefix)
            [
              control_objective_item.issues_count.to_s,
              control_objective_item.alerts_count.to_s
            ]
          else
            []
          end
        )
      end
    end
end
