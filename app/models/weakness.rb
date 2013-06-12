class Weakness < Finding
  # Acceso a los atributos
  attr_reader :approval_errors
  attr_protected :highest_risk

  # Callbacks
  before_save :assign_highest_risk

  # Named scopes
  scope :all_for_report, where(
    :state => STATUS.except(*EXCLUDE_FROM_REPORTS_STATUS).values,
    :final => true
  ).order(['risk DESC', 'state ASC'])
  scope :with_highest_risk, where(
    "#{table_name}.highest_risk = #{table_name}.risk"
  )
  scope :with_medium_risk, where(
    "#{table_name}.risk = (#{table_name}.highest_risk - 1) "
  )

  # Restricciones
  validates :risk, :priority, :presence => true
  validates :audit_recommendations, :presence => true, :if => :notify?
  validates_each :review_code do |record, attr, value|
    prefix = record.get_parameter(:admin_code_prefix_for_weaknesses, false,
      record.control_objective_item.try(:review).try(:organization).try(:id))
    regex = /\A#{prefix}\d+\Z/

    record.errors.add attr, :invalid unless value =~ regex
  end

  def initialize(attributes = nil, options = {}, import_users = false)
    super(attributes, options, import_users)

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

  def assign_highest_risk
    organization_id = GlobalModelConfig.current_organization_id ||
      self.control_objective_item.try(:review).try(:period).try(:organization_id)
    risks = self.get_parameter(:admin_finding_risk_levels, false,
      organization_id)
    self.highest_risk = risks.map(&:last).max
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
    return true if self.revoked?

    errors = []

    if self.implemented_audited? && self.solution_date.blank?
      errors << I18n.t('weakness.errors.without_solution_date')
    elsif self.implemented?
      if self.solution_date?
        errors << I18n.t('weakness.errors.with_solution_date')
      end

      unless self.follow_up_date?
        errors << I18n.t('weakness.errors.without_follow_up_date')
      end
    elsif self.being_implemented?
      if self.answer.blank?
        errors << I18n.t('weakness.errors.without_answer')
      end

      if self.solution_date?
        errors << I18n.t('weakness.errors.with_solution_date')
      end

      unless self.follow_up_date?
        errors << I18n.t('weakness.errors.without_follow_up_date')
      end
    elsif self.assumed_risk? && self.follow_up_date?
      errors << I18n.t('weakness.errors.with_follow_up_date')
    elsif !self.implemented_audited? && !self.implemented? &&
        !self.being_implemented? && !self.unconfirmed? &&
        !self.assumed_risk?
      errors << I18n.t('weakness.errors.not_valid_state')
    end

    unless self.has_audited?
      errors << I18n.t('weakness.errors.without_audited')
    end

    unless self.has_auditor?
      errors << I18n.t('weakness.errors.without_auditor')
    end

    errors << I18n.t('weakness.errors.without_effect') if self.effect.blank?

    if self.audit_comments.blank? && !self.revoked?
      errors << I18n.t('weakness.errors.without_audit_comments')
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

  def self.weaknesses_for_graph(weaknesses)
    data = []
    grouped_weaknesses = weaknesses.group_by(&:state)

    grouped_weaknesses.each do |status, weaknesses|
      data << { :label => weaknesses.first.state_text, :value => weaknesses.size }
    end

    data
  end

  def self.pending_weaknesses_for_graph(weaknesses)
    data = []
    being_implemented_counts = {
      :current => 0, :current_rescheduled => 0, :stale => 0 , :stale_rescheduled => 0
    }

    weaknesses.with_pending_status.each do |w|
      unless w.stale?
        unless w.rescheduled?
          being_implemented_counts[:current] += 1
        else
          being_implemented_counts[:current_rescheduled] += 1
        end
      else
        unless w.rescheduled?
          being_implemented_counts[:stale] += 1
        else
          being_implemented_counts[:stale_rescheduled] += 1
        end
      end
    end

    being_implemented_counts.each do |label, value|
      unless value == 0
        data << {
          :label => I18n.t(
            "follow_up_committee.weaknesses_being_implemented_#{label}",
            :count => value),
          :value => value}
      end
    end

    data
  end
end
