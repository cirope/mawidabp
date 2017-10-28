class ConclusionFinalReview < ConclusionReview
  include ConclusionFinalReviews::Scopes
  include ConclusionFinalReviews::Search
  include ConclusionFinalReviews::Sort
  include ConclusionFinalReviews::Validations

  # Callbacks
  before_create :check_if_can_be_created, :duplicate_review_findings

  # Restricciones de los atributos
  attr_readonly :issue_date, :close_date, :conclusion, :applied_procedures

  # Relaciones
  has_one :conclusion_draft_review, through: :review

  def initialize(attributes = nil, import_from_draft = true)
    super attributes

    if import_from_draft && self.review
      draft = ConclusionDraftReview.where(review_id: self.review_id).first

      self.attributes = draft.attributes if draft
    end
  end

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

  def duplicate_review_findings
    findings = self.review.weaknesses.not_revoked + self.review.oportunities.not_revoked

    begin
      findings.all? do |f|
        finding = f.dup
        finding.final = true
        finding.parent = f
        finding.origination_date ||= f.origination_date ||= self.issue_date

        f.business_unit_findings.each do |buf|
          finding.business_unit_findings.build(
            buf.attributes.dup.merge('id' => nil, 'finding_id' => nil)
          )
        end

        f.finding_user_assignments.each do |fua|
          finding.finding_user_assignments.build(
            fua.attributes.dup.merge('id' => nil, 'finding_id' => nil)
          )
        end

        f.work_papers.each do |wp|
          finding.work_papers.build(
            wp.attributes.dup.merge('id' => nil)
          ).check_code_prefix = false
        end

        finding.save!
        f.save!
      end

      revoked_findings = self.review.weaknesses.revoked + self.review.oportunities.revoked

      revoked_findings.each do |rf|
        rf.final = true
        rf.save! validate: false
      end
    rescue ActiveRecord::RecordInvalid
      errors.add :base, I18n.t('conclusion_final_review.stale_object_error')

      raise ActiveRecord::Rollback
    end
  end

  def is_frozen?
    self.close_date && Date.today > self.close_date
  end

  private

    def check_if_can_be_created
      throw :abort unless check_for_approval
    end
end
