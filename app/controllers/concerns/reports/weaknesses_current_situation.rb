module Reports::WeaknessesCurrentSituation
  extend ActiveSupport::Concern

  include Reports::FileResponder
  include Reports::Pdf
  include Reports::Period

  def weaknesses_current_situation
    init_weaknesses_current_situation_vars

    respond_to do |format|
      format.html
      format.csv  { render_current_situation_report_csv }
    end
  end

  def create_weaknesses_current_situation
    init_weaknesses_current_situation_vars

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    unless @cut_date == Time.zone.today
      pdf.add_description_item(
        t("#{@controller}_committee_report.weaknesses_current_situation.cut_date"),
        l(@cut_date),
        0,
        false
      )

      pdf.move_down PDF_FONT_SIZE
    end

    if @weaknesses.any?
      @weaknesses.each_with_index do |weakness, index|
        title = [
          "<b>#{index + 1}</b>",
          "<i>#{BusinessUnit.model_name.human}:</i>",
          weakness.business_unit
        ].join(' ')

        pdf.text title, size: PDF_FONT_SIZE, inline_format: true, align: :justify

        current_situation_pdf_items(weakness).each do |item|
          text = "<i>#{item.first}:</i> #{item.last.to_s.strip}"

          pdf.text text, size: PDF_FONT_SIZE, inline_format: true, align: :justify
        end

        pdf.move_down PDF_FONT_SIZE
      end
    else
      pdf.move_down PDF_FONT_SIZE
      pdf.text(
        t("#{@controller}_committee_report.weaknesses_current_situation.without_weaknesses"),
        style: :italic
      )
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_current_situation')

    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_current_situation')
  end

  def create_weaknesses_current_situation_permalink
    init_weaknesses_current_situation_vars

    if @weaknesses.any?
      action = if @controller == 'follow_up'
                 'follow_up_audit/weaknesses_current_situation'
               else
                 'execution_reports/weaknesses_current_situation'
               end

      @permalink = Permalink.list.new action: action

      @weaknesses.each do |weakness|
        @permalink.permalink_models.build model: weakness
      end

      @permalink.save!
    end
  end

  private

    def init_weaknesses_current_situation_vars
      @permalink = Permalink.list.find_by token: params[:permalink_token]
      @controller = weaknesses_current_situation_controller
      @title = t("#{@controller}_committee_report.weaknesses_current_situation_title")
      @from_date, @to_date = *make_date_range(params[:weaknesses_current_situation])
      @cut_date = extract_cut_date params[:weaknesses_current_situation]
      @filters = []
      final = params[:final] == 'true'
      order = [
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'risk'} DESC",
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'origination_date'} ASC",
        "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'conclusion_index'} DESC"
      ].map { |o| Arel.sql o }
      weaknesses = if @permalink
                     current_situation_weaknesses_from_permalink final
                   else
                     current_situation_weaknesses final
                   end

      @weaknesses = weaknesses.reorder order
    end

    def current_situation_weaknesses_from_permalink final
      current_situation_weaknesses_scope.
        finals(final).
        where(id: @permalink.permalink_models.pluck('model_id')).
        includes(:business_unit, :business_unit_type, :latest,
          achievements: [:benefit],
          review: [:plan_item, :conclusion_final_review],
          taggings: :tag
        )
    end

    def current_situation_weaknesses final
      weaknesses = current_situation_weaknesses_scope.
        with_repeated_status_for_report(execution: @controller == 'execution').
        finals(final).
        includes(:business_unit, :business_unit_type, :latest,
          achievements: [:benefit],
          review: [:plan_item, :conclusion_final_review],
          taggings: :tag
        )

      if params[:weaknesses_current_situation]
        weaknesses = filter_weaknesses_current_situation_by_risk weaknesses
        weaknesses = filter_weaknesses_current_situation_by_priority weaknesses
        weaknesses = filter_weaknesses_current_situation_by_status weaknesses
        weaknesses = filter_weaknesses_current_situation_by_title weaknesses
        weaknesses = filter_weaknesses_current_situation_by_compliance weaknesses
        weaknesses = filter_weaknesses_current_situation_by_business_unit_type weaknesses
        weaknesses = filter_weaknesses_current_situation_by_impact weaknesses
        weaknesses = filter_weaknesses_current_situation_by_operational_risk weaknesses
        weaknesses = filter_weaknesses_current_situation_by_internal_control_components weaknesses
        weaknesses = filter_weaknesses_current_situation_by_tags weaknesses
        weaknesses = filter_weaknesses_current_situation_by_repeated weaknesses
        weaknesses = filter_weaknesses_current_situation_by_review weaknesses
        weaknesses = filter_weaknesses_current_situation_by_conclusion weaknesses
        weaknesses = filter_weaknesses_current_situation_by_scope weaknesses
      end

      weaknesses
    end

    def current_situation_weaknesses_scope
      scoped = if @controller == 'follow_up'
        Weakness.list_for_report
      elsif @controller == 'execution'
        Weakness.list_without_final_review
      end

      if @permalink
        scoped
      elsif @controller == 'follow_up'
        scoped.by_issue_date 'BETWEEN', @from_date, @to_date
      elsif @controller == 'execution'
        scoped.by_origination_date 'BETWEEN', @from_date, @to_date
      end
    end

    def render_current_situation_report_csv
      render_or_send_by_mail(
        collection:  @weaknesses,
        filename:    "#{@title.downcase}.csv",
        method_name: :current_situation_csv
      )
    end

    def current_situation_pdf_items weakness
      current_weakness = weakness.current

      [
        [
          PlanItem.human_attribute_name('project'),
          weakness.review.plan_item.project
        ],
        [
          Review.model_name.human,
          weakness.review.identification
        ],
        [
          BusinessUnitType.model_name.human,
          weakness.business_unit_type
        ],
        [
          I18n.t("#{@controller}_committee_report.weaknesses_current_situation.origination_year"),
          (l(weakness.origination_date, format: '%Y') if weakness.origination_date)
        ],
        [
          ConclusionFinalReview.human_attribute_name('conclusion'),
          weakness.review.conclusion_final_review&.conclusion
        ],
        [
          Weakness.human_attribute_name('risk'),
          current_weakness.risk_text
        ],
        [
          Weakness.human_attribute_name('priority'),
          current_weakness.priority_text
        ],
        [
          "<font size='#{PDF_FONT_SIZE + 2}'>#{Weakness.human_attribute_name('title')}</font>",
          "<font size='#{PDF_FONT_SIZE + 2}'><b>#{current_weakness.title}</b></font>"
        ],
        [
          "<b>#{Weakness.human_attribute_name('description')}</b>",
          current_weakness.description
        ],
        ([
          "<b>#{Weakness.human_attribute_name('current_situation')}</b>",
          current_weakness.current_situation
        ] if current_weakness.show_current_situation?),
        [
          "<b>#{Weakness.human_attribute_name('answer')}</b>",
          current_weakness.answer
        ],
        [
          "<b>#{Weakness.human_attribute_name('state')}</b>",
          weakness.weaknesses_current_situation_state_text(current_weakness)
        ],
        ([
          "<b>#{Weakness.human_attribute_name('follow_up_date')}</b>",
          current_weakness.follow_up_date < (@cut_date - 30.days) ?
            "<color rgb='ff0000'>#{I18n.l(current_weakness.follow_up_date)}</color>" :
            I18n.l(current_weakness.follow_up_date)
        ] if current_weakness.follow_up_date)
      ].concat(
        weakness.achievements.map do |achievement|
          [
            achievement.benefit.to_s,
            achievement.amount ?
              '%.2f' % achievement.amount :
              achievement.comment
          ]
        end
      ).compact
    end

    def filter_weaknesses_current_situation_by_risk weaknesses
      risk = Array(params[:weaknesses_current_situation][:risk]).reject(&:blank?).map &:to_i

      if risk.present?
        risk_texts = risk.map do |r|
          t "risk_types.#{Weakness.risks.invert[r]}"
        end

        @filters << "<b>#{Finding.human_attribute_name('risk')}</b> = \"#{risk_texts.to_sentence}\""

        weaknesses.by_risk risk
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_priority weaknesses
      priority = params[:weaknesses_current_situation][:priority]

      if priority.present?
        priority      = priority.to_i
        priority_text = t "priority_types.#{Weakness.priorities.invert[priority]}"

        @filters << "<b>#{Finding.human_attribute_name('priority')}</b> = \"#{priority_text}\""

        weaknesses.by_priority_on_risk medium: priority
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_repeated weaknesses
      repeated = params[:weaknesses_current_situation][:repeated]

      return weaknesses if repeated.blank?

      repeated = repeated == 'true'

      @filters << "<b>#{t 'findings.state.repeated'}</b>: #{t("label.#{repeated ? 'yes' : 'no'}")}"

      repeated ? weaknesses.with_repeated : weaknesses.without_repeated
    end

    def filter_weaknesses_current_situation_by_status weaknesses
      states               = Array(params[:weaknesses_current_situation][:finding_status]).reject(&:blank?).map &:to_i
      not_muted_states     = Finding::EXCLUDE_FROM_REPORTS_STATUS + [:implemented_audited]
      mute_state_filter_on = Finding::STATUS.except(*not_muted_states).values

      if states.present?
        unless states.sort == mute_state_filter_on.sort
          state_text = states.map do |s|
            t "findings.state.#{Finding::STATUS.invert[s]}"
          end

          @filters << "<b>#{Finding.human_attribute_name('state')}</b> = \"#{state_text.to_sentence}\""
        end

        weaknesses.where state: states
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_title weaknesses
      if params[:weaknesses_current_situation][:finding_title].present?
        title = params[:weaknesses_current_situation][:finding_title]

        @filters << "<b>#{Finding.human_attribute_name('title')}</b> = \"#{title}\""

        weaknesses.with_title title
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_compliance weaknesses
      if params[:weaknesses_current_situation][:compliance].present?
        compliance = params[:weaknesses_current_situation][:compliance]

        @filters << "<b>#{Finding.human_attribute_name('compliance')}</b> = \"#{t "label.#{compliance}"}\""

        weaknesses.where compliance: compliance
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_business_unit_type weaknesses
      business_unit_types = Array(params[:weaknesses_current_situation][:business_unit_type]).reject(&:blank?)

      if business_unit_types.present?
        selected_business_units = BusinessUnitType.list.where id: business_unit_types

        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{selected_business_units.pluck('name').to_sentence}\""

        weaknesses.by_business_unit_type selected_business_units.ids
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_impact weaknesses
      impact = Array(params[:weaknesses_current_situation][:impact]).reject(&:blank?)

      if impact.present?
        @filters << "<b>#{Weakness.human_attribute_name('impact')}</b> = \"#{impact.to_sentence}\""

        weaknesses.by_impact impact
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_operational_risk weaknesses
      operational_risk = Array(params[:weaknesses_current_situation][:operational_risk]).reject(&:blank?)

      if operational_risk.present?
        @filters << "<b>#{Weakness.human_attribute_name('operational_risk')}</b> = \"#{operational_risk.to_sentence}\""

        weaknesses.by_operational_risk operational_risk
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_internal_control_components weaknesses
      internal_control_components = Array(params[:weaknesses_current_situation][:internal_control_components]).reject(&:blank?)

      if internal_control_components.present?
        @filters << "<b>#{Weakness.human_attribute_name('internal_control_components')}</b> = \"#{internal_control_components.to_sentence}\""

        weaknesses.by_internal_control_components internal_control_components
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_tags weaknesses
      weaknesses = filter_weaknesses_current_situation_by_control_objective_tags weaknesses
      weaknesses = filter_weaknesses_current_situation_by_weakness_tags weaknesses

      filter_weaknesses_current_situation_by_review_tags weaknesses
    end

    def filter_weaknesses_current_situation_by_control_objective_tags weaknesses
      tags = params[:weaknesses_current_situation][:control_objective_tags].to_s.split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip).reject(&:blank?)

      if tags.any?
        @filters << "<b>#{t "#{@controller}_committee_report.weaknesses_current_situation.control_objective_tags"}</b> = \"#{tags.to_sentence}\""

        weaknesses.by_control_objective_tags tags
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_weakness_tags weaknesses
      negate = params[:weaknesses_current_situation][:negate_weakness_tags] == '1'
      tags   = params[:weaknesses_current_situation][:weakness_tags].to_s.split(
        SPLIT_OR_TERMS_REGEXP
      ).uniq.map(&:strip).reject(&:blank?)

      if tags.any?
        @filters << "<b>#{t "#{@controller}_committee_report.weaknesses_current_situation.weakness_tags"}</b> = \"#{tags.to_sentence}\""

        weaknesses.by_wilcard_tags tags, negate: negate
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_review_tags weaknesses
      tags = params[:weaknesses_current_situation][:review_tags].to_s.split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip).reject(&:blank?)

      if tags.any?
        @filters << "<b>#{t "#{@controller}_committee_report.weaknesses_current_situation.review_tags"}</b> = \"#{tags.to_sentence}\""

        weaknesses.by_review_tags tags
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_review weaknesses
      {
        review: Review.model_name.human,
        project: Review.human_attribute_name('plan_item_id')
      }.each do |field, label|
        if params[:weaknesses_current_situation][field].present?
          filter = params[:weaknesses_current_situation][field]

          @filters << "<b>#{label}</b> = \"#{filter}\""

          weaknesses = weaknesses.send "by_#{field}", filter
        end
      end

      weaknesses
    end

    def filter_weaknesses_current_situation_by_conclusion weaknesses
      conclusions = Array(params[:weaknesses_current_situation][:conclusion]).reject(&:blank?)

      if conclusions.any?
        @filters << "<b>#{ConclusionFinalReview.human_attribute_name 'conclusion'}</b> = \"#{conclusions.to_sentence}\""

        weaknesses.where(conclusion_reviews: { type: 'ConclusionFinalReview', conclusion: conclusions })
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_scope weaknesses
      scopes = Array(params[:weaknesses_current_situation][:scope]).reject(&:blank?)

      if scopes.any?
        @filters << "<b>#{Review.human_attribute_name 'scope'}</b> = \"#{scopes.to_sentence}\""

        weaknesses.where(reviews: { scope: scopes })
      else
        weaknesses
      end
    end

    def weaknesses_current_situation_controller
      if @permalink && @permalink.action.start_with?('execution_reports')
        'execution'
      elsif (params[:controller_name] || controller_name).start_with?('follow_up')
        'follow_up'
      else
        'execution'
      end
    end
end
