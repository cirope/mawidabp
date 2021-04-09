module Reports::WeaknessesReschedules
  extend ActiveSupport::Concern

  include ActionView::Helpers::TextHelper
  include Reports::Pdf
  include Reports::Period

  def weaknesses_reschedules
    init_weaknesses_reschedules_vars

    respond_to do |format|
      format.html
      format.csv do
        render csv: weaknesses_reschedules_csv, filename: @title.downcase
      end
    end
  end

  private

    def init_weaknesses_reschedules_vars
      @controller = params[:controller_name]
      @title = t("#{@controller}_committee_report.weaknesses_reschedules_title")
      @from_date, @to_date = *make_date_range(params[:weaknesses_reschedules])
      final = params[:final] == 'true'

      weaknesses = Weakness.
        finals(false).
        where(state: Finding::PENDING_STATUS - [Finding::STATUS[:incomplete]]).
        list_for_report.
        by_issue_date('BETWEEN', @from_date, @to_date).
        includes(review: [:conclusion_final_review, :plan_item]).
        preload(finding_user_assignments: :user)

      if params[:weaknesses_reschedules]
        weaknesses = filter_weaknesses_reschedules_by_review weaknesses
        weaknesses = filter_weaknesses_reschedules_by_user weaknesses
      end

      @weaknesses = weaknesses.reorder weaknesses_reschedules_order
    end

    def weaknesses_reschedules_csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = CSV.generate(**options) do |csv|
        csv << weaknesses_reschedules_csv_headers

        weaknesses_reschedules_csv_data_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end

    def weaknesses_reschedules_csv_headers
      [
        Review.model_name.human,
        PlanItem.human_attribute_name('project'),
        BusinessUnitType.model_name.human,
        BusinessUnit.model_name.human,
        Weakness.human_attribute_name('review_code'),
        Weakness.human_attribute_name('title'),
        Weakness.human_attribute_name('description'),
        Weakness.human_attribute_name('state'),
        Weakness.human_attribute_name('risk'),
        FindingUserAssignment.human_attribute_name('process_owner'),
        I18n.t('finding.audited', count: 0),
        Finding.human_attribute_name('origination_date'),
        Finding.human_attribute_name('follow_up_date'),
        Finding.human_attribute_name('first_follow_up_date'),
        Finding.human_attribute_name('rescheduled'),
        Finding.human_attribute_name('reschedule_count'),
        t("#{@controller}_committee_report.weaknesses_reschedules.reschedule_count_manager"),
        t("#{@controller}_committee_report.weaknesses_reschedules.reschedule_count_management"),
        t("#{@controller}_committee_report.weaknesses_reschedules.reschedule_count_ceo"),
        t("#{@controller}_committee_report.weaknesses_reschedules.reschedule_count_committee")
      ]
    end

    def weaknesses_reschedules_csv_data_rows
      @weaknesses.map do |weakness|
        [
          weakness.review.identification,
          weakness.review.plan_item.project,
          weakness.business_unit_type.name,
          weakness.business_unit.name,
          weakness.review_code,
          weakness.title,
          weakness.description,
          weakness.state_text,
          weakness.try(:risk_text) || '',
          weakness.process_owners.map(&:full_name).join('; '),
          weakness.send(:audited_users).join('; '),
          weakness.send(:origination_date_text),
          weakness.send(:follow_up_date_text),
          weakness.send(:first_follow_up_date_text),
          weakness.send(:rescheduled_text),
          weakness.reschedule_count.to_s,
          Array(Hash(weakness.commitments)['manager']).size,
          Array(Hash(weakness.commitments)['management']).size,
          Array(Hash(weakness.commitments)['ceo']).size,
          Array(Hash(weakness.commitments)['committee']).size
        ]
      end
    end

    def weaknesses_reschedules_order
      order_by = params[:weaknesses_reschedules] && params[:weaknesses_reschedules][:order_by]

      if order_by == 'risk'
        [
          "#{Weakness.quoted_table_name}.#{Weakness.qcn 'risk'} DESC",
          "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} ASC",
          "#{Review.quoted_table_name}.#{Review.qcn 'identification'} ASC",
          "#{Weakness.quoted_table_name}.#{Weakness.qcn 'review_code'} ASC"
        ].map { |o| Arel.sql o }
      elsif order_by == 'first_follow_up_date'
        [
          "#{Weakness.quoted_table_name}.#{Weakness.qcn 'first_follow_up_date'} DESC",
          "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} ASC",
          "#{Review.quoted_table_name}.#{Review.qcn 'identification'} ASC",
          "#{Weakness.quoted_table_name}.#{Weakness.qcn 'review_code'} ASC"
        ].map { |o| Arel.sql o }
      else
        [
          "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} ASC",
          "#{Review.quoted_table_name}.#{Review.qcn 'identification'} ASC",
          "#{Weakness.quoted_table_name}.#{Weakness.qcn 'risk'} DESC",
          "#{Weakness.quoted_table_name}.#{Weakness.qcn 'review_code'} ASC"
        ].map { |o| Arel.sql o }
      end
    end

    def filter_weaknesses_reschedules_by_review weaknesses
      %i(review project).each do |field|
        if params[:weaknesses_reschedules][field].present?
          weaknesses = weaknesses.send "by_#{field}", params[:weaknesses_reschedules][field]
        end
      end

      weaknesses
    end

    def filter_weaknesses_reschedules_by_user weaknesses
      if params[:weaknesses_reschedules][:user_id].present?
        user     = User.find params[:weaknesses_reschedules][:user_id]
        inverted = params[:weaknesses_reschedules][:user_inverted] == '1'
        method   = inverted ? :excluding_user_id : :by_user_id

        weaknesses.send method, user.id
      else
        weaknesses
      end
    end
end
