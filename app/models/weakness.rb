class Weakness < Finding
  # Acceso a los atributos
  attr_reader :approval_errors

  # Named scopes
  scope :all_for_report, where(
    :state => STATUS.except(*EXCLUDE_FROM_REPORTS_STATUS).values,
    :final => true
  ).order(['risk DESC', 'state ASC'])

  # Restricciones
  validates :risk, :priority, :presence => true
  validates_each :review_code do |record, attr, value|
    prefix = record.get_parameter(:admin_code_prefix_for_weaknesses, false,
      record.control_objective_item.try(:review).try(:organization).try(:id))
    regex = /\A#{prefix}\d+\Z/

    record.errors.add attr, :invalid unless value =~ regex
  end

  def initialize(attributes = nil, import_users = false)
    super(attributes, import_users)

    self.review_code ||= self.next_code
  end

  def self.columns_for_sort
    Finding.columns_for_sort.dup.merge(
      :follow_up_date => {
        :name => Weakness.human_attribute_name(:follow_up_date),
        :field => "#{Weakness.table_name}.follow_up_date ASC"
      }
    )
  end

  def prepare_work_paper(work_paper)
    work_paper.code_prefix = self.get_parameter(self.finding_prefix ?
        :admin_code_prefix_for_work_papers_in_weaknesses_follow_up :
        :admin_code_prefix_for_work_papers_in_weaknesses)
  end
  
  def risk_text
    risks = self.get_parameter(:admin_finding_risk_levels)
    risk = risks.detect { |r| r.last == self.risk }

    risk.try(:first) || ''
  end

  def priority_text
    priority = self.get_parameter(:admin_priorities).detect do |p|
      p.last == self.priority
    end

    priority.try(:first) || ''
  end

  def rescheduled?
    self.all_follow_up_dates.size > 0
  end

  def next_code(review = nil)
    review ||= self.control_objective_item.try(:reload).try(:review)
    code_prefix = self.parameter_in(GlobalModelConfig.current_organization_id,
      :admin_code_prefix_for_weaknesses, review.try(:created_at))

    review ? review.next_weakness_code(code_prefix) : "#{code_prefix}1".strip
  end

  def last_work_paper_code(review = nil)
    review ||= self.control_objective_item.try(:reload).try(:review)
    code_prefix = self.parameter_in(GlobalModelConfig.current_organization_id,
      :admin_code_prefix_for_work_papers_in_weaknesses, review.try(:created_at))

    code_from_review = review ?
      review.last_weakness_work_paper_code(code_prefix) :
      "#{code_prefix} 0".strip

    code_from_weakness = self.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_weakness].compact.max
  end

  def must_be_approved?
    errors = []

    if self.implemented_audited? && self.solution_date.blank?
      errors << I18n.t(:'weakness.errors.without_solution_date')
    elsif self.implemented?
      if self.solution_date?
        errors << I18n.t(:'weakness.errors.with_solution_date')
      end

      unless self.follow_up_date?
        errors << I18n.t(:'weakness.errors.without_follow_up_date')
      end
    elsif self.being_implemented?
      if self.answer.blank?
        errors << I18n.t(:'weakness.errors.without_answer')
      end
      
      if self.solution_date?
        errors << I18n.t(:'weakness.errors.with_solution_date')
      end

      unless self.follow_up_date?
        errors << I18n.t(:'weakness.errors.without_follow_up_date')
      end
    elsif self.assumed_risk? && self.follow_up_date?
      errors << I18n.t(:'weakness.errors.with_follow_up_date')
    elsif !self.implemented_audited? && !self.implemented? &&
        !self.being_implemented? && !self.unconfirmed? &&
        !self.assumed_risk?
      errors << I18n.t(:'weakness.errors.not_valid_state')
    end

    unless self.has_audited?
      errors << I18n.t(:'weakness.errors.without_audited')
    end

    unless self.has_auditor?
      errors << I18n.t(:'weakness.errors.without_auditor')
    end

    errors << I18n.t(:'weakness.errors.without_effect') if self.effect.blank?

    if self.audit_comments.blank?
      errors << I18n.t(:'weakness.errors.without_audit_comments')
    end

    (@approval_errors = errors).blank?
  end

  def all_follow_up_dates(end_date = nil, reload = false)
    @all_follow_up_dates = reload ? [] : (@all_follow_up_dates || [])

    if @all_follow_up_dates.empty?
      last_date = self.follow_up_date
      dates = self.versions_after_final_review(end_date).map do |v|
        v.reify(:has_one => false).try(:follow_up_date)
      end

      dates.each do |d|
        unless d.blank? || d == last_date
          @all_follow_up_dates << d
          last_date = d
        end
      end
    end

    @all_follow_up_dates.compact
  end
end