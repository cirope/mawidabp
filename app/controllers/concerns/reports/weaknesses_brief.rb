module Reports::WeaknessesBrief
  extend ActiveSupport::Concern

  include Reports::Period

  def weaknesses_brief
    init_weaknesses_brief_vars

    respond_to do |format|
      format.html
      format.csv do
        render csv: weaknesses_brief_csv, filename: @title.downcase
      end
    end
  end

  private

    def init_weaknesses_brief_vars
      @controller = params[:controller_name]
      @title = t("#{@controller}_committee_report.weaknesses_brief_title")
      @from_date, @to_date = *make_date_range(params[:weaknesses_brief])
      @cut_date = extract_cut_date params[:weaknesses_brief]
      @filters = []
      final = params[:final] == 'true'
      order = [
        "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} ASC",
        "#{Review.quoted_table_name}.#{Review.qcn 'identification'} ASC",
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'risk'} ASC",
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'review_code'} ASC"
      ].map { |o| Arel.sql o }
      weaknesses = Weakness.
        awaiting.
        or(Weakness.being_implemented).
        or(Weakness.implemented).
        finals(final).
        list_with_final_review.
        by_issue_date('BETWEEN', @from_date, @to_date).
        includes(
          review: [:conclusion_final_review, :plan_item],
          finding_user_assignments: :user
        )

      @weaknesses = weaknesses.reorder order
    end

    def weaknesses_brief_csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = ::CSV.generate(options) do |csv|
        csv << weaknesses_brief_csv_headers

        weaknesses_brief_csv_data_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end

    def weaknesses_brief_csv_headers
      [
        Review.model_name.human,
        PlanItem.human_attribute_name('project'),
        Weakness.human_attribute_name('title'),
        Weakness.human_attribute_name('description'),
        Weakness.human_attribute_name('risk'),
        Weakness.human_attribute_name('audit_comments'),
        FindingUserAssignment.human_attribute_name('process_owner'),
        ConclusionFinalReview.human_attribute_name('issue_date'),
        Weakness.human_attribute_name('first_follow_up_date'),
        Weakness.human_attribute_name('follow_up_date'),
        t("#{@controller}_committee_report.weaknesses_brief.distance_to_cut_date")
      ]
    end

    def weaknesses_brief_csv_data_rows
      @weaknesses.map do |weakness|
        [
          weakness.review.identification,
          weakness.review.plan_item.project,
          weakness.title,
          weakness.description,
          weakness.risk_text,
          weakness.audit_comments,
          weaknesses_brief_audit_users(weakness).join("\n"),
          l(weakness.review.conclusion_final_review.issue_date),
          (weakness.first_follow_up_date ? l(weakness.first_follow_up_date) : '-'),
          (weakness.follow_up_date ? l(weakness.follow_up_date) : '-'),
          distance_in_days_to_cut_date(weakness)
        ]
      end
    end

    def weaknesses_brief_audit_users weakness
      weakness.
        finding_user_assignments.
        select { |fua| fua.user.can_act_as_audited? }.
        map(&:user).
        map(&:full_name)
    end

    def distance_in_days_to_cut_date weakness
      if weakness.first_follow_up_date
        distance = (@cut_date - weakness.first_follow_up_date).days / 1.day

        distance.abs.to_i > 365 ? distance.abs.to_i : nil
      end
    end

    def extract_cut_date parameters
      cut_date = Timeliness.parse parameters[:cut_date], :date if parameters

      cut_date&.to_date || Time.zone.today
    end
end
