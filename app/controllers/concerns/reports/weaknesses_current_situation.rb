module Reports::WeaknessesCurrentSituation
  extend ActiveSupport::Concern

  include Reports::Pdf
  include Reports::Period

  def weaknesses_current_situation
    init_weaknesses_current_situation_vars

    respond_to do |format|
      format.html
      format.csv do
        render csv: weaknesses_current_situation_csv, filename: @title.downcase
      end
    end
  end

  def create_weaknesses_current_situation
    init_weaknesses_current_situation_vars

    pdf = init_pdf params[:report_title], params[:report_subtitle]

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
      @permalink = Permalink.list.new action: 'follow_up_audit/weaknesses_current_situation'

      @weaknesses.each do |weakness|
        @permalink.permalink_models.build model: weakness
      end

      @permalink.save!
    end
  end

  private

    def init_weaknesses_current_situation_vars
      @controller = params[:controller_name] || (controller_name.start_with?('follow_up') ? 'follow_up' : 'conclusion')
      @title = t("#{@controller}_committee_report.weaknesses_current_situation_title")
      @from_date, @to_date = *make_date_range(params[:weaknesses_current_situation])
      @filters = []
      @permalink = Permalink.list.find_by token: params[:permalink_token]
      @benefits = Benefit.list.order kind: :desc, created_at: :asc
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
      Weakness.
        list_with_final_review.
        finals(final).
        where(id: @permalink.permalink_models.pluck('model_id')).
        includes(:business_unit, :business_unit_type,
          achievements: [:benefit],
          review: [:plan_item, :conclusion_final_review],
          taggings: :tag
        )
    end

    def current_situation_weaknesses final
      weaknesses = Weakness.
        with_repeated_status_for_report.
        finals(final).
        list_with_final_review.
        by_issue_date('BETWEEN', @from_date, @to_date).
        includes(:business_unit, :business_unit_type,
          achievements: [:benefit],
          review: [:plan_item, :conclusion_final_review],
          taggings: :tag
        )

      if params[:weaknesses_current_situation]
        weaknesses = filter_weaknesses_current_situation_by_risk weaknesses
        weaknesses = filter_weaknesses_current_situation_by_status weaknesses
        weaknesses = filter_weaknesses_current_situation_by_title weaknesses
        weaknesses = filter_weaknesses_current_situation_by_compliance weaknesses
        weaknesses = filter_weaknesses_current_situation_by_business_unit_type weaknesses
        weaknesses = filter_weaknesses_current_situation_by_impact weaknesses
        weaknesses = filter_weaknesses_current_situation_by_operational_risk weaknesses
        weaknesses = filter_weaknesses_current_situation_by_internal_control_components weaknesses
        weaknesses = filter_weaknesses_current_situation_by_tags weaknesses
        weaknesses = filter_weaknesses_current_situation_by_repeated weaknesses
      end

      weaknesses
    end

    def weaknesses_current_situation_csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = CSV.generate(options) do |csv|
        csv << weaknesses_current_situation_csv_headers

        weaknesses_current_situation_csv_data_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end

    def current_situation_pdf_items weakness
      current_weakness = current_weakness_for weakness

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
          I18n.t('follow_up_committee_report.weaknesses_current_situation.origination_year'),
          (l(weakness.origination_date, format: '%Y') if weakness.origination_date)
        ],
        [
          ConclusionFinalReview.human_attribute_name('conclusion'),
          weakness.review.conclusion_final_review.conclusion
        ],
        [
          Weakness.human_attribute_name('risk'),
          current_weakness.risk_text
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
        ] if show_current_situation? current_weakness),
        [
          "<b>#{Weakness.human_attribute_name('answer')}</b>",
          current_weakness.answer
        ],
        [
          "<b>#{Weakness.human_attribute_name('state')}</b>",
          weaknesses_current_situation_state_text(weakness, current_weakness)
        ],
        ([
          "<b>#{Weakness.human_attribute_name('follow_up_date')}</b>",
          current_weakness.follow_up_date < Time.zone.today ?
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

    def show_current_situation? weakness
      weakness.current_situation.present? && weakness.current_situation_verified
    end

    def filter_weaknesses_current_situation_by_risk weaknesses
      risk = Array(params[:weaknesses_current_situation][:risk]).reject(&:blank?)

      if risk.present?
        risk_texts = risk.map do |r|
          t "risk_types.#{Weakness.risks.invert[r.to_i]}"
        end

        @filters << "<b>#{Finding.human_attribute_name('risk')}</b> = \"#{risk_texts.to_sentence}\""

        weaknesses.by_risk risk
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
      states               = Array(params[:weaknesses_current_situation][:finding_status]).reject(&:blank?)
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
        @filters << "<b>#{t 'follow_up_committee_report.weaknesses_current_situation.control_objective_tags'}</b> = \"#{tags.to_sentence}\""

        weaknesses.by_control_objective_tags tags
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_weakness_tags weaknesses
      tags = params[:weaknesses_current_situation][:weakness_tags].to_s.split(
        SPLIT_OR_TERMS_REGEXP
      ).uniq.map(&:strip).reject(&:blank?)

      if tags.any?
        @filters << "<b>#{t 'follow_up_committee_report.weaknesses_current_situation.weakness_tags'}</b> = \"#{tags.to_sentence}\""

        weaknesses.by_wilcard_tags tags
      else
        weaknesses
      end
    end

    def filter_weaknesses_current_situation_by_review_tags weaknesses
      tags = params[:weaknesses_current_situation][:review_tags].to_s.split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip).reject(&:blank?)

      if tags.any?
        @filters << "<b>#{t 'follow_up_committee_report.weaknesses_current_situation.review_tags'}</b> = \"#{tags.to_sentence}\""

        weaknesses.by_review_tags tags
      else
        weaknesses
      end
    end

    def weaknesses_current_situation_csv_headers
      [
        BusinessUnit.model_name.human,
        PlanItem.human_attribute_name('project'),
        Review.model_name.human,
        BusinessUnitType.model_name.human,
        t('follow_up_committee_report.weaknesses_current_situation.origination_year'),
        ConclusionFinalReview.human_attribute_name('conclusion'),
        Weakness.human_attribute_name('risk'),
        Weakness.human_attribute_name('title'),
        Weakness.human_attribute_name('description'),
        Weakness.human_attribute_name('current_situation'),
        Weakness.human_attribute_name('answer'),
        Weakness.human_attribute_name('state'),
        Weakness.human_attribute_name('follow_up_date'),
        Weakness.human_attribute_name('solution_date'),
        Finding.human_attribute_name('id'),
        t('finding.audited', count: 0),
        t('finding.auditors', count: 0),
        Tag.model_name.human(count: 0)
      ].concat @benefits.pluck('name')
    end

    def weaknesses_current_situation_csv_data_rows
      @weaknesses.map do |weakness|
        current_weakness = current_weakness_for weakness

        [
          weakness.business_unit.to_s,
          weakness.review.plan_item.project,
          weakness.review.identification,
          weakness.business_unit_type.to_s,
          (l weakness.origination_date, format: '%Y' if weakness.origination_date),
          weakness.review.conclusion_final_review.conclusion,
          current_weakness.risk_text,
          current_weakness.title,
          current_weakness.description,
          (show_current_situation?(current_weakness) ? current_weakness.current_situation : ''),
          current_weakness.answer,
          weaknesses_current_situation_state_text(weakness, current_weakness),
          (l current_weakness.follow_up_date if current_weakness.follow_up_date),
          (l weakness.solution_date if weakness.solution_date),
          weakness.id,
          weakness.users.select(&:can_act_as_audited?).map(&:full_name).join('; '),
          weakness.users.reject(&:can_act_as_audited?).map(&:full_name).join('; '),
          weakness.taggings.map(&:tag).join('; ')
        ].concat(@benefits.map do |b|
          achievement = weakness.achievements.detect do |a|
            a.benefit_id == b.id
          end

          if achievement&.amount
            '%.2f' % achievement.amount
          else
            achievement&.comment
          end
        end)
      end
    end

    def current_weakness_for weakness
      if weakness.repeated? && weakness.repeated_in.present?
        weakness.repeated_leaf
      else
        weakness
      end
    end

    def weaknesses_current_situation_state_text weakness, current_weakness
      if weakness.id != current_weakness.id
        review           = current_weakness.review
        repeated_details = [
          current_weakness.review_code,
          review.identification,
          current_weakness.state_text
        ].join ' - '

        state_text = if review.has_final_review?
                       weakness.state_text
                     else
                       t 'follow_up_committee_report.weaknesses_current_situation.on_revision'
                     end

        "#{state_text} (#{repeated_details})"
      else
        weakness.state_text
      end
    end
end
