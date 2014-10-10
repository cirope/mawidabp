class Nonconformity < Finding

  # Acceso a los atributos
  attr_reader :approval_errors

  # Named scopes
  scope :all_for_report, -> { where(
    :state => STATUS.except(*EXCLUDE_FROM_REPORTS_STATUS).values,
    :final => true
    ).order(['risk DESC', 'state ASC'])
  }

  # Restricciones
  validates :risk, :priority, :presence => true
  validates :audit_recommendations, :presence => true, :if => :notify?
  validates :correction, :correction_date, :cause_analysis, :cause_analysis_date,
    :presence => true, :if => :audited_and_system_quality_management?
  validates_date :correction_date, :cause_analysis_date,
    :allow_nil => true, :allow_blank => true
  validates_date :correction_date, :on_or_before => :cause_analysis_date,
    :on_or_before_message => I18n.t('finding.errors.correction_date_on_or_before'),
    :allow_nil => true, :allow_blank => true
  validates_date :cause_analysis_date, :on_or_before => :follow_up_date,
    :on_or_before_message => I18n.t('finding.errors.cause_analysis_date_on_or_before'),
    :allow_nil => true, :allow_blank => true
  validates_each :review_code do |record, attr, value|
    regex = /\A#{record.prefix}\d+\Z/

    record.errors.add attr, :invalid unless value =~ regex
  end

  def initialize(attributes = nil, options = {}, import_users = false)
    super(attributes, options, import_users)

    self.review_code ||= self.next_code
  end

  def self.columns_for_sort
    Finding.columns_for_sort.dup.merge(
      :follow_up_date => {
        :name => Nonconformity.human_attribute_name(:follow_up_date),
        :field => "#{Nonconformity.table_name}.follow_up_date ASC"
      }
    )
  end

  def prepare_work_paper(work_paper)
    work_paper.code_prefix = self.finding_prefix ?
      I18n.t('code_prefixes.work_papers_in_weaknesses_follow_up') :
      work_paper_prefix
  end

  def risk_text
    risk = self.class.risks.detect { |r| r.last == self.risk }

    risk ? I18n.t("risk_types.#{risk.first}") : ''
  end

  def priority_text
    priority = self.class.priorities.detect { |p| p.last == self.priority }

    priority ? I18n.t("priority_types.#{priority.first}") : ''
  end

  def rescheduled?
    self.all_follow_up_dates.size > 0
  end

  def prefix
    I18n.t('code_prefixes.nonconformities')
  end

  def work_paper_prefix
    I18n.t('code_prefixes.work_papers_in_nonconformities')
  end

  def next_code(review = nil)
    review ||= self.control_objective_item.try(:reload).try(:review)

    review ? review.next_nonconformity_code(prefix) : "#{prefix}1".strip
  end

  def last_work_paper_code(review = nil)
    review ||= self.control_objective_item.try(:reload).try(:review)

    code_from_review = review ?
      review.last_nonconformity_work_paper_code(work_paper_prefix) :
      "#{work_paper_prefix} 0".strip

    code_from_nonconformity = self.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{work_paper_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_nonconformity].compact.max
  end

  def must_be_approved?
    return true if self.revoked?

    errors = []

    if self.implemented_audited? && self.solution_date.blank?
      errors << I18n.t('nonconformity.errors.without_solution_date')
    elsif self.implemented?
      if self.solution_date?
        errors << I18n.t('nonconformity.errors.with_solution_date')
      end

      unless self.follow_up_date?
        errors << I18n.t('nonconformity.errors.without_follow_up_date')
      end
    elsif self.being_implemented?
      if self.answer.blank?
        errors << I18n.t('nonconformity.errors.without_answer')
      end

      if self.solution_date?
        errors << I18n.t('nonconformity.errors.with_solution_date')
      end

      unless self.follow_up_date?
        errors << I18n.t('nonconformity.errors.without_follow_up_date')
      end

    elsif self.assumed_risk? && self.follow_up_date?
      errors << I18n.t('nonconformity.errors.with_follow_up_date')
    elsif !self.implemented_audited? && !self.implemented? &&
        !self.being_implemented? && !self.unconfirmed? &&
        !self.assumed_risk?
      errors << I18n.t('nonconformity.errors.not_valid_state')
    end

    unless self.has_audited?
      errors << I18n.t('nonconformity.errors.without_audited')
    end

    unless self.has_auditor?
      errors << I18n.t('nonconformity.errors.without_auditor')
    end

    errors << I18n.t('nonconformity.errors.without_effect') if self.effect.blank?

    if self.audit_comments.blank? && !self.revoked?
      errors << I18n.t('nonconformity.errors.without_audit_comments')
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

  def self.nonconformities_for_graph(nonconformities)
    data = []
    grouped_nonconformities = nonconformities.group_by(&:state)

    grouped_nonconformities.each do |status, nonconformities|
      data << { :label => nonconformities.first.state_text, :value => nonconformities.size }
    end

    data
  end

  def self.pending_nonconformities_for_graph(nonconformities)
    data = []
    being_implemented_counts = {
      :current => 0, :current_rescheduled => 0, :stale => 0 , :stale_rescheduled => 0
    }

    nonconformities.with_pending_status.each do |w|
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
            "follow_up_committee.nonconformities_being_implemented_#{label}",
            :count => value),
          :value => value}
      end
    end

    data
  end
end
