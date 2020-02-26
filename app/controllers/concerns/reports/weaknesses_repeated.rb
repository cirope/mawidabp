module Reports::WeaknessesRepeated
  extend ActiveSupport::Concern

  include Reports::FileResponder
  include Reports::Pdf
  include Reports::Period

  def weaknesses_repeated
    init_weaknesses_repeated_vars

    respond_to do |format|
      format.html
      format.csv  { render_repeated_report_csv }
    end
  end

  def create_weaknesses_repeated
    init_weaknesses_repeated_vars

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    if @weaknesses.any?
      @weaknesses.each_with_index do |weakness, index|
        repeated_pdf_items(weakness).each do |item|
          text = "<i>#{item.first}:</i> #{item.last.to_s.strip}"

          pdf.text text, size: PDF_FONT_SIZE, inline_format: true, align: :justify
        end

        put_repeated_current_on pdf, weakness

        pdf.move_down PDF_FONT_SIZE
      end
    else
      pdf.move_down PDF_FONT_SIZE
      pdf.text(
        t("#{@controller}_committee_report.weaknesses_repeated.without_weaknesses"),
        style: :italic
      )
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_repeated')

    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_repeated')
  end

  private

    def init_weaknesses_repeated_vars
      @controller = params[:controller_name] || 'follow_up'
      @title = t("#{@controller}_committee_report.weaknesses_repeated_title")
      @from_date, @to_date = *make_date_range(params[:weaknesses_repeated])
      @filters = []
      final = params[:final] == 'true'
      order = [
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'risk'} DESC",
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'origination_date'} ASC",
        "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'conclusion_index'} DESC"
      ].map { |o| Arel.sql o }
      weaknesses = repeated_weaknesses final

      @weaknesses = weaknesses.reorder order
    end

    def repeated_weaknesses final
      weaknesses = Weakness.repeated.or(Weakness.being_implemented).
        finals(final).
        list_with_final_review.
        by_issue_date('BETWEEN', @from_date, @to_date).
        includes(:business_unit, :business_unit_type, :latest,
          achievements: [:benefit],
          review: [:plan_item, :conclusion_final_review],
          taggings: :tag
        )

      if params[:weaknesses_repeated]
        weaknesses = filter_weaknesses_repeated_by_weakness_tags weaknesses
      end

      weaknesses
    end

    def render_repeated_report_csv
      render_or_send_by_mail(
        collection:  @weaknesses,
        filename:    "#{@title.downcase}.csv",
        method_name: :repeated_csv
      )
    end

    def put_repeated_current_on pdf, weakness
      unless weakness == weakness.current
        pdf.move_down PDF_FONT_SIZE * 0.5

        pdf.indent PDF_FONT_SIZE do
          repeated_current_pdf_items(weakness).each do |item|
            text = "<i>#{item.first}:</i> #{item.last.to_s.strip}"

            pdf.text text, size: PDF_FONT_SIZE, inline_format: true, align: :justify
          end
        end
      end
    end

    def repeated_pdf_items weakness
      [
        [
          Review.model_name.human,
          weakness.review.identification
        ],
        [
          PlanItem.human_attribute_name('project'),
          weakness.review.plan_item.project
        ],
        [
          I18n.t('follow_up_committee_report.weaknesses_repeated.origination_year'),
          (l(weakness.origination_date, format: '%Y') if weakness.origination_date)
        ],
        [
          Weakness.human_attribute_name('risk'),
          weakness.risk_text
        ],
        ([
          Weakness.human_attribute_name('state'),
          weakness.state_text
        ] unless weakness.repeated?),
        [
          Weakness.human_attribute_name('title'),
          weakness.title
        ],
        [
          Weakness.human_attribute_name('description'),
          weakness.description
        ],
        [
          Weakness.human_attribute_name('answer'),
          weakness.answer
        ]
      ].compact
    end

    def repeated_current_pdf_items weakness
      current_weakness = weakness.current

      [
        [
          Review.model_name.human,
          current_weakness.review.identification
        ],
        [
          Weakness.human_attribute_name('risk'),
          current_weakness.risk_text
        ],
        [
          Weakness.human_attribute_name('state'),
          current_weakness.state_text
        ],
        [
          Weakness.human_attribute_name('answer'),
          current_weakness.answer
        ],
        [
          Weakness.human_attribute_name('follow_up_date'),
          current_weakness.follow_up_date ? I18n.l(current_weakness.follow_up_date) : '-'
        ]
      ]
    end

    def filter_weaknesses_repeated_by_weakness_tags weaknesses
      tags = params[:weaknesses_repeated][:weakness_tags].to_s.split(
        SPLIT_OR_TERMS_REGEXP
      ).uniq.map(&:strip).reject(&:blank?)

      if tags.any?
        @filters << "<b>#{t 'follow_up_committee_report.weaknesses_repeated.weakness_tags'}</b> = \"#{tags.to_sentence}\""

        weaknesses.by_wilcard_tags tags
      else
        weaknesses
      end
    end
end
