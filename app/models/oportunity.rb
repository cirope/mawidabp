class Oportunity < Finding
  # Acceso a los atributos
  attr_reader :approval_errors

  # Named scopes
  scope :all_for_report, -> {
    where(
      :state => STATUS.except(*EXCLUDE_FROM_REPORTS_STATUS).values,
      :final => true
    ).order(:state => :asc)
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
    work_paper.code_prefix = work_paper_prefix
  end

  def prefix
    I18n.t('code_prefixes.oportunities')
  end

  def work_paper_prefix
    I18n.t('code_prefixes.work_papers_in_oportunities')
  end

  def next_code(review = nil)
    review ||= self.control_objective_item.try(:reload).try(:review)

    review ? review.next_oportunity_code(prefix) : "#{prefix}1".strip
  end

  def last_work_paper_code(review = nil)
    review ||= self.control_objective_item.try(:reload).try(:review)

    code_from_review = review ?
      review.last_oportunity_work_paper_code(work_paper_prefix) :
      "#{work_paper_prefix} 0".strip

    code_from_oportunity = self.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{work_paper_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_oportunity].compact.max
  end

  def must_be_approved?
    return true if self.revoked? || self.criteria_mismatch?

    errors = []

    if self.implemented_audited? && self.solution_date.blank?
      errors << I18n.t('oportunity.errors.without_solution_date')
    elsif self.implemented?
      if self.solution_date?
        errors << I18n.t('oportunity.errors.with_solution_date')
      end
    elsif self.being_implemented?
      if self.answer.blank?
        errors << I18n.t('oportunity.errors.without_answer')
      end

      if self.solution_date?
        errors << I18n.t('oportunity.errors.with_solution_date')
      end
    elsif self.assumed_risk? && self.follow_up_date?
      errors << I18n.t('oportunity.errors.with_follow_up_date')
    elsif !self.implemented_audited? && !self.implemented? &&
        !self.being_implemented? && !self.unconfirmed? &&
        !self.assumed_risk?
      errors << I18n.t('oportunity.errors.not_valid_state')
    end

    unless self.has_audited?
      errors << I18n.t('oportunity.errors.without_audited')
    end

    unless self.has_auditor?
      errors << I18n.t('oportunity.errors.without_auditor')
    end

    if self.audit_comments.blank? && !self.revoked?
      errors << I18n.t('oportunity.errors.without_audit_comments')
    end

    (@approval_errors = errors).blank?
  end
end
