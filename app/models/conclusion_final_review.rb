class ConclusionFinalReview < ConclusionReview
  include ConclusionFinalReviews::Defaults
  include ConclusionFinalReviews::Destroy
  include ConclusionFinalReviews::Scopes
  include ConclusionFinalReviews::Search
  include ConclusionFinalReviews::Sort
  include ConclusionFinalReviews::Validations

  # Callbacks
  before_create :check_if_can_be_created,
                :sort_findings_if_apply,
                :duplicate_review_findings,
                :assign_audit_date_to_control_objective_items

  # Restricciones de los atributos
  attr_readonly :issue_date, :close_date, :conclusion, :applied_procedures

  # Relaciones
  has_one :conclusion_draft_review, through: :review

  def check_for_approval
    self.approved = self.review && (self.review.is_approved? ||
        (self.review.can_be_approved_by_force &&
          self.review.conclusion_draft_review.try(:approved)))

    if self.approved?
      true
    else
      self.errors.add :review_id, :invalid

      false
    end
  end

  def sort_findings_if_apply
    if method = sort_findings_by_method
      review.send method
      review.reload
    end
  end

  def duplicate_review_findings
    findings = self.review.weaknesses.not_revoked + self.review.oportunities.not_revoked

    begin
      findings.all? do |finding|
        final_finding = finding.dup
        final_finding.final = true
        final_finding.parent = finding
        final_finding.skip_work_paper = finding.skip_work_paper = true
        final_finding.origination_date ||= finding.origination_date ||= self.issue_date

        finding.business_unit_findings.each do |buf|
          final_finding.business_unit_findings.build(
            buf.attributes.dup.merge('id' => nil, 'finding_id' => nil)
          )
        end

        finding.finding_user_assignments.each do |fua|
          final_finding.finding_user_assignments.build(
            fua.attributes.dup.merge('id' => nil, 'finding_id' => nil)
          )
        end

        finding.tasks.each do |t|
          final_finding.tasks.build(
            t.attributes.dup.merge('id' => nil, 'finding_id' => nil)
          )
        end

        finding.taggings.each do |t|
          final_finding.taggings.build(
            t.attributes.dup.merge('id' => nil, 'taggable_id' => nil)
          )
        end

        finding.work_papers.each do |wp|
          final_finding.work_papers.build(
            wp.attributes.dup.merge('id' => nil)
          ).check_code_prefix = false
        end

        final_finding.save!
        finding.save!
      end

      revoked_findings = self.review.weaknesses.revoked + self.review.oportunities.revoked

      revoked_findings.each do |rf|
        rf.final = true
        rf.save! validate: false
      end
    rescue ActiveRecord::RecordInvalid => ex
      errors.add :base, I18n.t('conclusion_final_review.stale_object_error')

      Rails.logger.error ex.inspect
      raise ActiveRecord::Rollback
    end
  end

  def assign_audit_date_to_control_objective_items
    if DISABLE_COI_AUDIT_DATE_VALIDATION
      begin
        review.control_objective_items.each do |coi|
          if coi.audit_date.blank?
            coi.update! audit_date: issue_date
          end
        end
      rescue ActiveRecord::RecordInvalid => ex
        errors.add :base, I18n.t('conclusion_final_review.stale_object_error')

        Rails.logger.error ex.inspect
        raise ActiveRecord::Rollback
      end
    end
  end

  def is_frozen?
    close_date && Time.zone.today > close_date
  end

  private

    def check_if_can_be_created
      throw :abort unless check_for_approval
    end

    def sort_findings_by_method
      methods = JSON.parse ENV['AUTOMATICALLY_SORT_FINDINGS_ON_CONCLUSION'] || '{}'

      methods[organization.prefix] if organization && methods.present?
    end
end
