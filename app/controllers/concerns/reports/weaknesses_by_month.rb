module Reports::WeaknessesByMonth
  extend ActiveSupport::Concern

  include Reports::Pdf
  include Reports::Period

  def weaknesses_by_month
    @controller = params[:controller_name]
    final = params[:final] == 'true'
    @title = t("#{@controller}_committee_report.weaknesses_by_month_title")
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_month])
    @months = months_for_interval
    @filters = []
    @reviews = {}
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(
      @from_date, @to_date
    )
    weaknesses_conditions = {}

    if params[:weaknesses_by_month]
      risk = params[:weaknesses_by_month][:risk]

      if params[:weaknesses_by_month][:business_unit_type].present?
        @selected_business_unit = BusinessUnitType.find(
          params[:weaknesses_by_month][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      if params[:weaknesses_by_month][:business_unit].present?
        business_units = params[:weaknesses_by_month][:business_unit].split(
          SPLIT_AND_TERMS_REGEXP
        ).uniq.map(&:strip)
        business_unit_ids = business_units.present? && BusinessUnit.by_names(*business_units).pluck('id')

        if business_units.present?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(*business_units)
          @filters << "<b>#{BusinessUnit.model_name.human}</b> = \"#{params[:weaknesses_by_month][:business_unit].strip}\""
        end
      end

      if params[:weaknesses_by_month][:finding_status].present?
        weaknesses_conditions[:state] = params[:weaknesses_by_month][:finding_status]
        state_text = t "findings.state.#{Finding::STATUS.invert[weaknesses_conditions[:state].to_i]}"

        @filters << "<b>#{Finding.human_attribute_name('state')}</b> = \"#{state_text}\""
      end

      if params[:weaknesses_by_month][:finding_title].present?
        weaknesses_conditions[:title] = params[:weaknesses_by_month][:finding_title]

        @filters << "<b>#{Finding.human_attribute_name('title')}</b> = \"#{weaknesses_conditions[:title]}\""
      end
    end

    @months.each do |month|
      BusinessUnitType.list.each do |but|
        conclusion_review_per_unit_type = conclusion_reviews.for_month(month).by_business_unit_type(but.id)

        sort_by_conclusion(conclusion_review_per_unit_type).each do |c_r|
          weaknesses = final ? c_r.review.final_weaknesses : c_r.review.weaknesses
          weaknesses = weaknesses.by_risk(risk) if risk.present?
          report_weaknesses = weaknesses.with_pending_status_for_report
          report_weaknesses = report_weaknesses.where(state: weaknesses_conditions[:state]) if weaknesses_conditions[:state]
          report_weaknesses = report_weaknesses.with_title(weaknesses_conditions[:title])   if weaknesses_conditions[:title]

          if report_weaknesses.any?
            @reviews[month] ||= []
            @reviews[month] << {
              conclusion_review: c_r,
              weaknesses: report_weaknesses
            }
          end
        end
      end
    end
  end

  # Crea un PDF con las observaciones por riesgo para un determinado rango
  # de fechas
  #
  # * POST /conclusion_committee_reports/create_weaknesses_by_month
  def create_weaknesses_by_month
    self.weaknesses_by_month

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    add_pdf_description pdf, @controller, @from_date, @to_date

    @months.each do |month|
      add_month_title pdf, month

      if @reviews[month].present?
        last_shown_business_unit_type_id = nil

        @reviews[month].each do |data|
          conclusion_review = data[:conclusion_review]
          review = conclusion_review.review

          unless last_shown_business_unit_type_id == review.business_unit_type.id
            pdf.move_down PDF_FONT_SIZE * 1.25
            pdf.add_title review.business_unit_type.name, (PDF_FONT_SIZE * 1.25).round

            last_shown_business_unit_type_id = review.business_unit_type.id
          end

          put_weaknesses_by_month_conclusion_review_on pdf, conclusion_review

          weaknesses = data[:weaknesses]

          put_weaknesses_by_month_main_weaknesses_on  pdf, weaknesses
          put_weaknesses_by_month_other_weaknesses_on pdf, weaknesses
        end
      else
        pdf.move_down PDF_FONT_SIZE
        pdf.text(
          t("#{@controller}_committee_report.weaknesses_by_month.without_audits_in_the_month"),
          style: :italic
        )
      end
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_by_month')

    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_by_month')
  end

  private

    def months_for_interval
      cursor = @from_date.at_beginning_of_month
      to     = @to_date.at_beginning_of_month
      list   = []

      while cursor <= to
        list << cursor

        cursor = cursor.advance(months: 1).at_beginning_of_month
      end

      list
    end

    def sort_by_conclusion conclusion_reviews
      conclusions_order = [
        'No satisfactorio',
        'Necesita mejorar',
        'Satisfactorio con salvedades',
        'Satisfactorio',
        'No aplica'
      ]

      conclusion_reviews.to_a.sort do |cr_1, cr_2|
        index_1 = conclusions_order.index cr_1.conclusion
        index_2 = conclusions_order.index cr_2.conclusion

        index_1 <=> index_2
      end
    end

    def put_weaknesses_by_month_conclusion_review_on pdf, conclusion_review
      review = conclusion_review.review

      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item Review.human_attribute_name('identification'),
        review.identification, 0, false, PDF_FONT_SIZE

      pdf.add_description_item ConclusionFinalReview.human_attribute_name('issue_date'),
        I18n.l(conclusion_review.issue_date), 0, false, PDF_FONT_SIZE

      pdf.add_description_item BusinessUnit.model_name.human,
        review.business_unit.name, 0, false, PDF_FONT_SIZE

      pdf.add_description_item Review.human_attribute_name('plan_item'),
        review.plan_item.project, 0, false, PDF_FONT_SIZE

      pdf.add_description_item ConclusionFinalReview.human_attribute_name('conclusion'),
        "     #{conclusion_review.conclusion}", 0, false, PDF_FONT_SIZE

      put_weaknesses_by_month_conclusion_image_on pdf, conclusion_review

      pdf.add_description_item ConclusionFinalReview.human_attribute_name('evolution'),
        "     #{conclusion_review.evolution}", 0, false, PDF_FONT_SIZE

      put_weaknesses_by_month_evolution_image_on pdf, conclusion_review

      pdf.add_description_item Review.human_attribute_name('risk_exposure'),
        review.risk_exposure, 0, false, PDF_FONT_SIZE
    end

    def put_weaknesses_by_month_conclusion_image_on pdf, conclusion_review
      text       = "#{ConclusionFinalReview.human_attribute_name 'conclusion'}: "
      image      = CONCLUSION_IMAGES[conclusion_review.conclusion]
      image_path = PDF_IMAGE_PATH.join(image || PDF_DEFAULT_SCORE_IMAGE)
      image_x    = pdf.width_of(text, size: PDF_FONT_SIZE, style: :bold)
      image_y    = pdf.cursor + (PDF_FONT_SIZE * 1.25)

      pdf.image image_path, fit: [10, 10], at: [image_x, image_y]
    end

    def put_weaknesses_by_month_evolution_image_on pdf, conclusion_review
      text       = "#{ConclusionFinalReview.human_attribute_name 'evolution'}: "
      image      = EVOLUTION_IMAGES[conclusion_review.evolution]
      image_path = PDF_IMAGE_PATH.join(image || PDF_DEFAULT_SCORE_IMAGE)
      image_x    = pdf.width_of(text, size: PDF_FONT_SIZE, style: :bold)
      image_y    = pdf.cursor + (PDF_FONT_SIZE * 1.25)

      pdf.image image_path, fit: [10, 10], at: [image_x, image_y]
    end

    def put_weaknesses_by_month_main_weaknesses_on pdf, weaknesses
      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t("#{@controller}_committee_report.weaknesses_by_month.main_weaknesses"),
        style: :bold, size: PDF_FONT_SIZE

      main_weaknesses = weaknesses.not_revoked.not_assumed_risk.with_high_risk.sort_by_code

      pdf.indent PDF_FONT_SIZE do
        if main_weaknesses.any?
          main_weaknesses.each do |w|
            put_weaknesses_by_month_main_weakness_on pdf, w
          end
        else
          pdf.move_down (PDF_FONT_SIZE * 0.5).round
          pdf.text(
            t("#{@controller}_committee_report.weaknesses_by_month.without_weaknesses"),
            style: :italic
          )
        end
      end
    end

    def put_weaknesses_by_month_main_weakness_on pdf, w
      origination_date = w.repeated_of_id ?
        l(w.origination_date, format: :long) :
        t('conclusion_review.new_origination_date')

      pdf.move_down (PDF_FONT_SIZE * 0.5).round

      pdf.add_description_item Weakness.human_attribute_name('title'),
        w.title, 0, false, PDF_FONT_SIZE
      pdf.add_description_item Weakness.human_attribute_name('risk'),
        w.risk_text, 0, false, PDF_FONT_SIZE
      pdf.add_description_item Weakness.human_attribute_name('origination_date'),
        origination_date, 0, false, PDF_FONT_SIZE
      pdf.add_description_item Weakness.human_attribute_name('description'),
        w.description, 0, false, PDF_FONT_SIZE
      pdf.add_description_item Weakness.human_attribute_name('answer'),
        w.answer, 0, false, PDF_FONT_SIZE

      if w.follow_up_date
        pdf.add_description_item t('conclusion_review.estimated_follow_up_date'),
          l(w.follow_up_date, format: '%B %Y'), 0, false, PDF_FONT_SIZE
      end
    end

    def put_weaknesses_by_month_other_weaknesses_on pdf, weaknesses
      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t("#{@controller}_committee_report.weaknesses_by_month.other_weaknesses"),
        style: :bold, size: PDF_FONT_SIZE

      other_weaknesses = weaknesses.not_revoked.not_assumed_risk.with_other_risk.sort_by_code

      pdf.indent PDF_FONT_SIZE do
        if other_weaknesses.any?
          pdf.move_down (PDF_FONT_SIZE * 0.5).round

          other_weaknesses.each do |w|
            put_weaknesses_by_month_other_weakness_on pdf, w
          end
        else
          pdf.move_down (PDF_FONT_SIZE * 0.5).round
          pdf.text(
            t("#{@controller}_committee_report.weaknesses_by_month.without_weaknesses"),
            style: :italic
          )
        end
      end
    end

    def put_weaknesses_by_month_other_weakness_on pdf, w
      text = [
        w.title,
        [Weakness.human_attribute_name('risk'), w.risk_text].join(': '),
        [
          Weakness.human_attribute_name('origination_date'),
          w.repeated_of_id ? l(w.origination_date) : t('conclusion_review.new_origination_date')
        ].join(': '),
        ([
          t("#{@controller}_committee_report.weaknesses_by_month.year"),
          l(w.origination_date, format: '%Y')
        ].join(': ') if w.repeated_of_id)
      ].compact.join(' - ')

      pdf.text "• #{text}"
    end
end
