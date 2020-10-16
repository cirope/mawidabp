module Reports::WeaknessesReport
  include Reports::FileResponder
  extend ActiveSupport::Concern

  included do
    before_action :set_weaknesses_for_report,
                  :set_title,
                  only: [:weaknesses_report, :create_weaknesses_report]
  end

  def weaknesses_report
    respond_to do |format|
      format.html { render_paginated_weaknesses }
      format.js   { render_paginated_weaknesses }
      format.csv  { render_weaknesses_report_csv }
    end
  end

  def create_weaknesses_report
    redirect_or_send_by_mail(
      collection:    @weaknesses,
      method_name:   :to_weakness_report_pdf,
      filename:      weaknesses_report_pdf_name,
      options:       {
        title:         params[:report_title],
        subtitle:      params[:report_subtitle],
        report_params: Hash(params[:weaknesses_report]&.permit!),
        filename:      weaknesses_report_pdf_name
      }
    )
  end

  private

    def set_weaknesses_for_report
      report_params = params[:weaknesses_report]

      if report_params.present?
        weaknesses = filter_weaknesses_for_report report_params
        order      = weaknesses.values[:order]

        # The double where by ids is because the relations are scoped by filters
        # within filter_weaknesses_for_report.
        @weaknesses = scoped_weaknesses.where(
          id: weaknesses.pluck(:id)
        ).includes(
          :finding_user_assignments,
          :repeated_of,
          :repeated_in,
          latest: :review,
          review: :plan_item,
          finding_answers: [:file_model, user: { organization_roles: :role }],
          users: { organization_roles: :role },
          control_objective_item: [:process_control]
        ).merge(
          Review.allowed_by_business_units
        ).order order
      else
        @weaknesses = Weakness.none
      end
    end

    def set_title
      @title = if params[:execution].present?
                 t 'execution_reports.weaknesses_report.title'
               else
                 t 'follow_up_audit.weaknesses_report.title'
               end
    end

    def scoped_weaknesses
      params[:execution].present? ?
        Weakness.list_without_final_review : Weakness.list_for_report
    end

    def filter_weaknesses_for_report report_params
      weaknesses = scoped_weaknesses.finals false

      %i(review project process_control control_objective).each do |param|
        if report_params[param].present?
          weaknesses = weaknesses.send "by_#{param}", report_params[param]
        end
      end

      if report_params[:tags].present?
        tags = report_params[:tags].to_s.split(
          SPLIT_OR_TERMS_REGEXP
        ).uniq.map(&:strip).reject(&:blank?)

        weaknesses = weaknesses.by_wilcard_tags tags if tags.any?
      end

      if report_params[:user_id].present?
        user_ids   = weaknesses_report_user_ids report_params
        weaknesses = weaknesses.by_user_id user_ids,
          include_finding_answers: report_params[:user_in_comments] == '1'
      end

      if report_params[:finding_status].present?
        weaknesses = weaknesses.where state: report_params[:finding_status].to_i
      end

      if report_params[:finding_current_situation_verified].present?
        verified   = report_params[:finding_current_situation_verified] == 'yes'
        weaknesses = weaknesses.where current_situation_verified: verified
      end

      if report_params[:repeated].present?
        if report_params[:repeated] == 'true'
          weaknesses = weaknesses.where.not repeated_of: nil
        else
          weaknesses = weaknesses.where repeated_of: nil
        end
      end

      if report_params[:compliance].present?
        weaknesses = weaknesses.where compliance: report_params[:compliance]
      end

      if report_params[:finding_title].present?
        weaknesses = weaknesses.with_title report_params[:finding_title]
      end

      %i(risk priority).each do |param|
        if report_params[param].present?
          weaknesses = weaknesses.where param => report_params[param].to_i
        end
      end

      if report_params[:issue_date].present?
        weaknesses = weaknesses.by_issue_date *parse_date_field(report_params, :issue_date)
      end

      %i(origination_date follow_up_date solution_date).each do |date_field|
        if report_params[date_field].present?
          operator, date, date_until = *parse_date_field(report_params, date_field)

          mask       = date_until ? '? AND ?' : '?'
          condition  = "#{Weakness.qcn date_field} #{operator} #{mask}"
          weaknesses = weaknesses.where condition, *[date, date_until].compact
        end
      end

      if params[:execution].blank?
        weaknesses.order [
          Arel.sql("#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} ASC"),
          review_code: :asc
        ]
      else
        weaknesses.order [
          Arel.sql("#{Review.quoted_table_name}.#{Review.qcn 'created_at'} ASC"),
          review_code: :asc
        ]
      end
    end

    def safe_date_operator operator
      %w(= < > <= >= between).include?(operator) ? operator : '='
    end

    def parse_date_field report_params, field_name
      operator     = safe_date_operator report_params["#{field_name}_operator"]
      date         = Timeliness.parse(report_params[field_name], :date).to_date
      date_until   = Timeliness.parse(report_params["#{field_name}_until"], :date)&.to_date
      date_until ||= date if operator == 'between'

      [operator.upcase, date, date_until]
    end

    def weaknesses_report_pdf_name
      params[:execution].present? ?
        t('execution_reports.weaknesses_report.pdf_name') :
        t('follow_up_audit.weaknesses_report.pdf_name')
    end

    def weaknesses_report_user_ids report_params
      if report_params[:include_user_tree] == '1'
        user = User.list.find report_params[:user_id]

        user.self_and_descendants.map &:id
      else
        report_params[:user_id].to_i
      end
    end

    def render_weaknesses_report_csv
      render_or_send_by_mail(
        collection:  @weaknesses,
        filename:    "#{@title.downcase}.csv",
        method_name: :to_csv
      )
    end

    def render_paginated_weaknesses
      @weaknesses = @weaknesses.page params[:page]
    end
end
