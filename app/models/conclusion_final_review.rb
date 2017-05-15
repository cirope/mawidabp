class ConclusionFinalReview < ConclusionReview
  include ConclusionFinalReviews::Scopes

  # Constantes
  COLUMNS_FOR_SEARCH = {
    close_date: {
      column: "#{table_name}.#{qcn('close_date')}",
      operator: SEARCH_ALLOWED_OPERATORS.values, mask: "%s",
      conversion_method: lambda { |value|
        Timeliness.parse(value, :date).to_s(:db)
      },
      regexp: SEARCH_DATE_REGEXP
    }
  }.merge(GENERIC_COLUMNS_FOR_SEARCH).with_indifferent_access

  # Callbacks
  before_create :check_if_can_be_created, :duplicate_review_findings

  # Restricciones de los atributos
  attr_readonly :issue_date, :close_date, :conclusion, :applied_procedures

  # Restricciones
  validates :close_date, :conclusion, presence: true
  validates :review_id, uniqueness: true, allow_blank: true,
    allow_nil: true
  validates_date :close_date, allow_nil: true, allow_blank: true,
    on: :create, on_or_after: :issue_date
  validates_each :review_id do |record, attr, value|
    if record.review && record.review.conclusion_draft_review
      unless record.review.conclusion_draft_review.approved?
        record.errors.add attr, :invalid
      end
    elsif record.review
      record.errors.add attr, :without_draft
    end
  end

  # Relaciones
  has_one :conclusion_draft_review, through: :review

  def self.columns_for_sort
    ConclusionReview.columns_for_sort.dup.merge(
      close_date: {
        name: ConclusionReview.human_attribute_name(:close_date),
        field: "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('close_date')} ASC"
      }
    )
  end

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
