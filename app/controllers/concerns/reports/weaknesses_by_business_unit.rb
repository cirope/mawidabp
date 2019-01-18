module Reports::WeaknessesByBusinessUnit
  extend ActiveSupport::Concern

  include Reports::PDF
  include Reports::Period

  def weaknesses_by_business_unit
    init_weaknesses_by_business_unit_vars

    respond_to do |format|
      format.html
      format.csv do
        render csv: weaknesses_by_business_unit_csv, filename: @title.downcase
      end
      format.rtf do
        render rtf: weaknesses_by_business_unit_rtf, filename: @title.downcase
      end
    end
  end

  def create_weaknesses_by_business_unit
    init_weaknesses_by_business_unit_vars

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    if @weaknesses.any?
      put_weaknesses_by_business_unit_on pdf
    else
      pdf.move_down PDF_FONT_SIZE
      pdf.text(
        t("#{@controller}_committee_report.weaknesses_by_business_unit.without_weaknesses"),
        style: :italic
      )
    end

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_by_business_unit')

    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_by_business_unit')
  end

  private

    def init_weaknesses_by_business_unit_vars
      @controller = params[:controller_name]
      @title = t("#{@controller}_committee_report.weaknesses_by_business_unit_title")
      @from_date, @to_date = *make_date_range(params[:weaknesses_by_business_unit])
      final = params[:final] == 'true'
      order = [
        "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} DESC",
        "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'id'} ASC",
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'risk'} DESC",
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'review_code'} ASC",
      ].map { |o| Arel.sql o }
      weaknesses = Weakness.
        with_status_for_report.
        finals(final).
        list_with_final_review.
        by_issue_date('BETWEEN', @from_date, @to_date).
        includes(
          :business_unit,
          :business_unit_type,
          finding_answers: :user,
          review: [:plan_item, :conclusion_final_review]
        )

      if params[:weaknesses_by_business_unit]
        weaknesses = filter_weaknesses_by_business_unit weaknesses
        weaknesses = filter_weaknesses_by_business_unit_by_risk weaknesses
        weaknesses = filter_weaknesses_by_business_unit_by_status weaknesses
        weaknesses = filter_weaknesses_by_business_unit_by_title weaknesses
        weaknesses = filter_weaknesses_by_business_unit_by_business_unit_type weaknesses
      else
        weaknesses = weaknesses.none
      end

      @weaknesses = weaknesses.reorder order
    end

    def weaknesses_by_business_unit_csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = ::CSV.generate(options) do |csv|
        csv << weaknesses_by_business_unit_csv_headers

        weaknesses_by_business_unit_csv_data_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end

    def weaknesses_by_business_unit_rtf
      document           = RTF::Document.new RTF::Font.new(RTF::Font::ROMAN, 'Arial')
      organization_image = current_organization.image_model&.image&.thumb&.path

      if organization_image && File.exists?(organization_image)
        header = RTF::HeaderNode.new document

        header.paragraph { |n| n.image(organization_image) }

        document.header = header
      end

      header_style           = RTF::CharacterStyle.new
      header_style.bold      = true
      header_style.font_size = 28

      document.paragraph header_style do |p|
        p << @title
      end

      document.line_break

      if @weaknesses.any?
        put_weaknesses_by_business_unit_paragraphs_on document
      else
        document.paragraph do |p|
          p.italic << t(
            "#{@controller}_committee_report.weaknesses_by_business_unit.without_weaknesses"
          )
        end
      end

      document.to_rtf
    end

    def by_business_unit_pdf_review_items weakness
      [
        [
          Review.model_name.human,
          weakness.review.identification
        ],
        [
          ConclusionFinalReview.human_attribute_name('issue_date'),
          l(weakness.review.conclusion_final_review.issue_date)
        ]
      ]
    end

    def by_business_unit_pdf_weakness_items weakness
      show_year        = show_weaknesses_by_business_unit_origination_date? weakness
      origination_date = if show_year
                           l weakness.origination_date, format: '%Y'
                         else
                           t 'conclusion_review.new_origination_date'
                         end

      [
        [
          Weakness.human_attribute_name('title'),
          weakness.title
        ],
        [
          Weakness.human_attribute_name('description'),
          weakness.description
        ],
        ([
          Weakness.human_attribute_name('current_situation'),
          weakness.current_situation
        ] if weakness.current_situation.present? && weakness.current_situation_verified),
        ([
          Weakness.human_attribute_name('answer'),
          weakness.answer
        ] unless weakness.implemented_audited?),
        [
          Weakness.human_attribute_name('state'),
          weakness.state_text
        ],
        [
          t("#{@controller}_committee_report.weaknesses_by_business_unit.year"),
          origination_date
        ]
      ].compact
    end

    def filter_weaknesses_by_business_unit weaknesses
      if params[:weaknesses_by_business_unit][:business_unit_id].present?
        business_unit_ids = JSON.parse params[:weaknesses_by_business_unit][:business_unit_id]
        business_units = BusinessUnit.list.where id: business_unit_ids

        weaknesses.by_business_unit_ids business_units.ids
      else
        weaknesses.none
      end
    end

    def filter_weaknesses_by_business_unit_by_risk weaknesses
      risk = Array(params[:weaknesses_by_business_unit][:risk]).reject(&:blank?)

      if risk.present?
        risk_texts = risk.map do |r|
          t "risk_types.#{Weakness.risks.invert[r.to_i]}"
        end

        weaknesses.by_risk risk
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_business_unit_by_status weaknesses
      states               = Array(params[:weaknesses_by_business_unit][:finding_status]).reject(&:blank?)
      not_muted_states     = Finding::EXCLUDE_FROM_REPORTS_STATUS + [:implemented_audited]
      mute_state_filter_on = Finding::STATUS.except(*not_muted_states).map do |k, v|
        v.to_s
      end

      if states.present?
        unless states.sort == mute_state_filter_on.sort
          state_text = states.map do |s|
            t "findings.state.#{Finding::STATUS.invert[s.to_i]}"
          end
        end

        weaknesses.where state: states
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_business_unit_by_title weaknesses
      if params[:weaknesses_by_business_unit][:finding_title].present?
        title = params[:weaknesses_by_business_unit][:finding_title]

        weaknesses.with_title title
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_business_unit_by_business_unit_type weaknesses
      business_unit_types = Array(params[:weaknesses_by_business_unit][:business_unit_type]).reject(&:blank?)

      if business_unit_types.present?
        selected_business_units = BusinessUnitType.list.where id: business_unit_types

        weaknesses.by_business_unit_type selected_business_units.ids
      else
        weaknesses
      end
    end

    def put_weaknesses_by_business_unit_on pdf
      @_review_index        ||= 1
      @_last_displayed_review = nil

      @weaknesses.each do |weakness|
        unless @_last_displayed_review == weakness.review.id
          title = [
            "<b>#{@_review_index}</b>",
            "<i>#{PlanItem.human_attribute_name 'project'}:</i>",
            weakness.review.plan_item.project
          ].join(' ')

          pdf.text title, size: PDF_FONT_SIZE, inline_format: true,
            align: :justify

          by_business_unit_pdf_review_items(weakness).each do |item|
            text = "<i>#{item.first}:</i> #{item.last.to_s.strip}"

            pdf.text text, size: PDF_FONT_SIZE, inline_format: true,
              align: :justify
          end

          pdf.move_down PDF_FONT_SIZE * 0.5

          @_review_index         += 1
          @_last_displayed_review = weakness.review.id
        end

        pdf.indent PDF_FONT_SIZE do
          by_business_unit_pdf_weakness_items(weakness).each do |item|
            text = "<i>#{item.first}:</i> #{item.last.to_s.strip}"

            pdf.text text, size: PDF_FONT_SIZE, inline_format: true,
              align: :justify
          end
        end

        pdf.move_down PDF_FONT_SIZE * 0.5
      end
    end

    def put_weaknesses_by_business_unit_paragraphs_on document
      @_review_index        ||= 1
      @_last_displayed_review = nil

      indented_style             = RTF::ParagraphStyle.new
      indented_style.left_indent = 400

      @weaknesses.each do |weakness|
        unless @_last_displayed_review == weakness.review.id
          document.paragraph do |p|
            p.bold   << "#{@_review_index} "
            p.italic << "#{PlanItem.human_attribute_name 'project'}: "
            p        << weakness.review.plan_item.project
          end

          by_business_unit_pdf_review_items(weakness).each do |item|
            document.paragraph do |p|
              p.italic << "#{item.first}: "
              p        << item.last.to_s.strip
            end
          end

          @_review_index         += 1
          @_last_displayed_review = weakness.review.id

          document.line_break
        end

        by_business_unit_pdf_weakness_items(weakness).each do |item|
          document.paragraph indented_style do |p|
            p.italic << "#{item.first}: "
            p        << item.last.to_s.strip
          end
        end

        document.line_break
      end
    end

    def weaknesses_by_business_unit_csv_headers
      [
        PlanItem.human_attribute_name('project'),
        Review.model_name.human,
        ConclusionFinalReview.human_attribute_name('issue_date'),
        Weakness.human_attribute_name('title'),
        Weakness.human_attribute_name('description'),
        Weakness.human_attribute_name('answer'),
        Weakness.human_attribute_name('state'),
        t("#{@controller}_committee_report.weaknesses_by_business_unit.year")
      ]
    end

    def weaknesses_by_business_unit_csv_data_rows
      @weaknesses.map do |weakness|
        show_year        = show_weaknesses_by_business_unit_origination_date? weakness
        origination_date = if show_year
                             l weakness.origination_date, format: '%Y'
                           else
                             t 'conclusion_review.new_origination_date'
                           end

        [
          weakness.review.plan_item.project,
          weakness.review.identification,
          l(weakness.review.conclusion_final_review.issue_date),
          weakness.title,
          weakness.description,
          weakness.answer,
          weakness.state_text,
          origination_date
        ]
      end
    end

    def show_weaknesses_by_business_unit_origination_date? weakness
      (weakness.repeated_of_id && weakness.origination_date) ||
        weakness.origination_date < 1.year.ago
    end
end


