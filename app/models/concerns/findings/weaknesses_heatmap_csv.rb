module Findings::WeaknessesHeatmapCsv
  extend ActiveSupport::Concern

  def weaknesses_heatmap_csv_data_rows
    auditors       = users.select &:auditor?
    auditeds       = users.select do |u|
      u.can_act_as_audited? && process_owners.exclude?(u)
    end

    [
      review.identification,
      review.plan_item.project,
      review.conclusion_final_review ? I18n.l(review.conclusion_final_review.issue_date) : '-',
      business_unit,
      review_code,
      title,
      auditors.map(&:full_name).join('; '),
      process_owners.map(&:full_name).join('; '),
      auditeds.map(&:full_name).join('; '),
      auditors.map(&:user).join('; '),
      process_owners.map(&:user).join('; '),
      auditeds.map(&:user).join('; '),
      description,
      state_text,
      risk_text,
      review.plan_item.risk_exposure,
      priority_text,
      (origination_date ? I18n.l(origination_date) : '-'),
      (follow_up_date ? I18n.l(follow_up_date) : '-'),
      (solution_date ? I18n.l(solution_date) : '-'),
      I18n.t("label.#{rescheduled? ? 'yes' : 'no'}"),
      I18n.t("label.#{repeated_of_id.present? ? 'yes' : 'no'}"),
      audit_comments,
      audit_recommendations,
      answer,
      (finding_answers.map { |fa|
        date = I18n.l fa.created_at, format: :minimal

        "[#{date}] #{fa.user.full_name}: #{fa.answer}"
      }.join("\n") if Weakness.show_follow_up_timestamps?),
      compliance_observations.to_s,
      review.conclusion_final_review.conclusion,
      review.conclusion_final_review.evolution,
      process_owner_parents.map(&:full_name).join(', '),
      process_owner_roots.map(&:full_name).join(', ')
    ].compact
  end

  module ClassMethods
    def weaknesses_heatmap_csv options = {}
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = CSV.generate(**options) do |csv|
        csv << weaknesses_heatmap_csv_headers
      end

      ChunkIterator.iterate all_with_inclusions do |cursor|
        csv_str += CSV.generate(**options) do |csv|
          cursor.each do |f|
            csv << f.weaknesses_heatmap_csv_data_rows
          end
        end
      end

      "\uFEFF#{csv_str}"
    end

    def weaknesses_heatmap_csv_headers
      [
        Review.model_name.human,
        PlanItem.human_attribute_name('project'),
        ConclusionFinalReview.human_attribute_name('issue_date'),
        BusinessUnit.model_name.human,
        Weakness.human_attribute_name('review_code'),
        Weakness.human_attribute_name('title'),
        I18n.t('finding.auditors', count: 0),
        I18n.t('finding.responsibles', count: 1),
        I18n.t('finding.audited', count: 0),
        I18n.t('finding.auditor_users', count: 0),
        I18n.t('finding.responsible_users', count: 1),
        I18n.t('finding.audited_users', count: 0),
        Weakness.human_attribute_name('description'),
        Weakness.human_attribute_name('state'),
        Weakness.human_attribute_name('risk'),
        PlanItem.human_attribute_name('risk_exposure'),
        Weakness.human_attribute_name('priority'),
        Weakness.human_attribute_name('origination_date'),
        Weakness.human_attribute_name('follow_up_date'),
        Weakness.human_attribute_name('solution_date'),
        Weakness.human_attribute_name('rescheduled'),
        I18n.t('findings.state.repeated'),
        Weakness.human_attribute_name('audit_comments'),
        Weakness.human_attribute_name('audit_recommendations'),
        Weakness.human_attribute_name('answer'),
        (I18n.t('finding.finding_answers') if Weakness.show_follow_up_timestamps?),
        Weakness.human_attribute_name('compliance_observations'),
        ConclusionReview.human_attribute_name('conclusion'),
        ConclusionReview.human_attribute_name('evolution'),
        I18n.t('follow_up_committee_report.weaknesses_heatmap.process_owner_parents'),
        I18n.t('follow_up_committee_report.weaknesses_heatmap.process_owner_roots'),
      ].compact
    end

    private

      def all_with_inclusions
        preload *[
          :repeated_of,
          :business_unit_type,
          :business_unit,
          latest: [:review, latest_answer: :user],
          finding_answers: [:user, :commitment_support, endorsements: :user],
          finding_user_assignments: :user,
          finding_owner_assignments: :user,
          users: {
            organization_roles: :role
          },
          control_objective_item: {
            review: [:plan_item, :conclusion_final_review]
          }
        ].compact
      end
  end
end
