module Findings::HeatmapByWeaknessesCsv
  extend ActiveSupport::Concern

  module ClassMethods
    def heatmap_by_weaknesses_csv options = {}
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = CSV.generate(**options) do |csv|
        csv << heatmap_by_weaknesses_csv_headers

        heatmap_by_weaknesses_csv_data_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end

    def heatmap_by_weaknesses_csv_headers
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
        I18n.t('follow_up_committee_report.heatmap_by_weaknesses.process_owner'),
        I18n.t('follow_up_committee_report.heatmap_by_weaknesses.user_root'),
      ].compact
    end

    def heatmap_by_weaknesses_csv_data_rows
      all.map do |weakness|
        auditors       = weakness.users.select &:auditor?
        process_owners = weakness.process_owners
        auditeds       = weakness.users.select do |u|
          u.can_act_as_audited? && weakness.process_owners.exclude?(u)
        end

        [
          weakness.review.identification,
          weakness.review.plan_item.project,
          weakness.review.conclusion_final_review ? I18n.l(weakness.review.conclusion_final_review.issue_date) : '-',
          weakness.business_unit,
          weakness.review_code,
          weakness.title,
          auditors.map(&:full_name).join('; '),
          process_owners.map(&:full_name).join('; '),
          auditeds.map(&:full_name).join('; '),
          auditors.map(&:user).join('; '),
          process_owners.map(&:user).join('; '),
          auditeds.map(&:user).join('; '),
          weakness.description,
          weakness.state_text,
          weakness.risk_text,
          weakness.review.plan_item.risk_exposure,
          weakness.priority_text,
          (weakness.origination_date ? I18n.l(weakness.origination_date) : '-'),
          (weakness.follow_up_date ? I18n.l(weakness.follow_up_date) : '-'),
          (weakness.solution_date ? I18n.l(weakness.solution_date) : '-'),
          I18n.t("label.#{weakness.rescheduled? ? 'yes' : 'no'}"),
          I18n.t("label.#{weakness.repeated_of_id.present? ? 'yes' : 'no'}"),
          weakness.audit_comments,
          weakness.audit_recommendations,
          weakness.answer,
          (weakness.finding_answers.map { |fa|
            date = I18n.l fa.created_at, format: :minimal

            "[#{date}] #{fa.user.full_name}: #{fa.answer}"
          }.join("\n") if Weakness.show_follow_up_timestamps?),
          weakness.compliance_observations.to_s,
          weakness.review.conclusion_final_review.conclusion,
          weakness.review.conclusion_final_review.evolution,
          user_manager(weakness.process_owners),
          user_root(weakness.process_owners)
        ].compact
      end
    end
  end
end
