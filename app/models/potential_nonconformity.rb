class PotentialNonconformity < Finding
# Acceso a los atributos
  attr_reader :approval_errors

  # Named scopes
  scope :all_for_report, -> {
    where(
      :state => STATUS.except(*EXCLUDE_FROM_REPORTS_STATUS).values,
      :final => true
    ).order('state ASC')
  }

  # Restricciones
  validates_each :review_code do |record, attr, value|
    regex = /\A#{record.prefix}\d+\Z/

    record.errors.add attr, :invalid unless value =~ regex
  end

  def initialize(attributes = nil, options = {}, import_users = false)
    super(attributes, options, import_users)

    self.review_code ||= self.next_code
  end

  def self.columns_for_sort
    Finding.columns_for_sort.except(
      :risk_asc, :risk_desc, :follow_up_date_asc, :follow_up_date_desc
    )
  end

  def prepare_work_paper(work_paper)
    work_paper.code_prefix =
      I18n.t('code_prefixes.work_papers_in_potential_nonconformities')
  end

  def prefix
    I18n.t('code_prefixes.potential_nonconformities')
  end

  def next_code(review = nil)
    review ||= self.control_objective_item.reload.review
    review.next_potential_nonconformity_code(self.prefix)
  rescue
    "#{self.prefix}1".strip
  end

  def last_work_paper_code(review = nil)
    code_prefix = I18n.t('code_prefixes.work_papers_in_potential_nonconformities')

    code_from_review = begin
      review ||= self.control_objective_item.reload.review
      review.last_potential_nonconformity_work_paper_code(code_prefix)
    rescue
      "#{code_prefix} 0".strip
    end

    code_from_potential_nonconformity = self.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_potential_nonconformity].compact.max
  end

  def must_be_approved?
    return true if self.revoked?

    errors = []

    if self.implemented_audited? && self.solution_date.blank?
      errors << I18n.t('potential_nonconformity.errors.without_solution_date')
    elsif self.implemented?
      if self.solution_date?
        errors << I18n.t('potential_nonconformity.errors.with_solution_date')
      end
    elsif self.being_implemented?
      if self.answer.blank?
        errors << I18n.t('potential_nonconformity.errors.without_answer')
      end

      if self.solution_date?
        errors << I18n.t('potential_nonconformity.errors.with_solution_date')
      end
    elsif self.assumed_risk? && self.follow_up_date?
      errors << I18n.t('potential_nonconformity.errors.with_follow_up_date')
    elsif !self.implemented_audited? && !self.implemented? &&
        !self.being_implemented? && !self.unconfirmed? &&
        !self.assumed_risk?
      errors << I18n.t('potential_nonconformity.errors.not_valid_state')
    end

    unless self.has_audited?
      errors << I18n.t('potential_nonconformity.errors.without_audited')
    end

    unless self.has_auditor?
      errors << I18n.t('potential_nonconformity.errors.without_auditor')
    end

    if self.audit_comments.blank? && !self.revoked?
      errors << I18n.t('potential_nonconformity.errors.without_audit_comments')
    end

    (@approval_errors = errors).blank?
  end
end
