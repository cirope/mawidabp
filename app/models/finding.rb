class Finding < ActiveRecord::Base
  include Comparable
  include ParameterSelector

  # Constantes
  COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new({
    :issue_date => {
      :column => "#{ConclusionReview.table_name}.issue_date",
      :operator => SEARCH_ALLOWED_OPERATORS.values, :mask => "%s",
      :conversion_method => lambda {
        |value| Timeliness::Parser.parse(value, :date)
      }, :regexp => SEARCH_DATE_REGEXP
    },
    :review => {
      :column => "LOWER(#{Review.table_name}.identification)",
      :operator => 'LIKE', :mask => "%%%s%%", :conversion_method => :to_s,
      :regexp => /.*/
    },
    :project => {
      :column => "LOWER(#{PlanItem.table_name}.project)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :review_code => {
      :column => "LOWER(#{table_name}.review_code)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :description => {
      :column => "LOWER(#{table_name}.description)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    }
  })

  acts_as_tree
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  STATUS = {
    :confirmed => -3,
    :unconfirmed => -2,
    :unanswered => -1,
    :being_implemented => 0,
    :implemented => 1,
    :implemented_audited => 2,
    :assumed_risk => 3,
    :notify => 4,
    :incomplete => 5
  }.freeze

  STATUS_TRANSITIONS = {
    :confirmed => [
      :confirmed,
      :unanswered,
      :being_implemented,
      :implemented,
      :implemented_audited,
      :assumed_risk
    ],
    :unconfirmed => [
      :unconfirmed,
      :confirmed,
      :unanswered
    ],
    :unanswered => [
      :unanswered,
      :being_implemented,
      :implemented,
      :implemented_audited,
      :assumed_risk
    ],
    :being_implemented => [
      :being_implemented,
      :implemented,
      :implemented_audited,
      :assumed_risk
    ],
    :implemented => [
      :implemented,
      :being_implemented,
      :implemented_audited,
      :assumed_risk
    ],
    :implemented_audited => [
      :implemented_audited
    ],
    :assumed_risk => [
      :assumed_risk
    ],
    :notify => [
      :notify,
      :incomplete,
      :being_implemented,
      :implemented,
      :implemented_audited,
      :assumed_risk
    ],
    :incomplete => [
      :incomplete,
      :notify,
      :being_implemented,
      :implemented,
      :implemented_audited,
      :assumed_risk
    ]
  }

  PENDING_STATUS = [
    STATUS[:being_implemented], STATUS[:notify], STATUS[:implemented],
    STATUS[:unconfirmed], STATUS[:confirmed], STATUS[:unanswered],
    STATUS[:incomplete]
  ]

  EXCLUDE_FROM_REPORTS_STATUS = [:unconfirmed, :confirmed, :notify, :incomplete]

  # Named scopes
  scope :with_prefix, lambda { |prefix|
    where('review_code LIKE ?', "#{prefix}%").order('review_code ASC')
  }
  scope :all_for_reallocation_with_review, lambda { |review|
    includes(:control_objective_item => :review).where(
      :reviews => {:id => review.id}, :state => PENDING_STATUS, :final => false
    )
  }
  scope :all_for_reallocation, where(:state => PENDING_STATUS, :final => false)
  scope :for_notification, where(:state => STATUS[:notify], :final => false)
  scope :finals, lambda { |use_finals| where(:final => use_finals) }
  scope :sort_by_code, order('review_code ASC')
  scope :for_period, lambda { |period|
    includes(:control_objective_item => { :review =>:period }).where(
      "#{Period.table_name}.id" => period.id
    )
  }
  scope :next_to_expire, lambda {
    where(
      [
        'follow_up_date = :warning_date',
        'state = :being_implemented_state',
        'final = :boolean_false'
      ].join(' AND '),
      {
        :warning_date =>
          FINDING_WARNING_EXPIRE_DAYS.days.from_now_in_business.to_date,
        :being_implemented_state => STATUS[:being_implemented],
        :boolean_false => false
      }
    )
  }
  scope :unconfirmed_for_notification, lambda {
    where(
      [
        'first_notification_date >= :stale_unconfirmed_date',
        'state = :state',
        'final = :boolean_false'
      ].join(' AND '),
      {
        :state => STATUS[:unconfirmed],
        :boolean_false => false,
        :stale_unconfirmed_date =>
          FINDING_STALE_UNCONFIRMED_DAYS.days.ago_in_business.to_date
      }
    )
  }
  scope :unanswered_and_stale, lambda { |factor|
    stale_parameters = Organization.all_parameters(
      :admin_finding_stale_confirmed_days)
    pre_conditions = []
    parameters = {
      :state => STATUS[:unanswered],
      :boolean_false => false,
      :notification_level => factor - 1
    }

    stale_parameters.each_with_index do |stale_parameter, i|
      stale_days = stale_parameter[:parameter].to_i
      parameters[:"stale_unanswered_date_#{i}"] =
        (stale_days + stale_days * factor).days.ago_in_business.to_date
      parameters[:"organization_id_#{i}"] = stale_parameter[:organization].id

      pre_conditions << [
        "first_notification_date < :stale_unanswered_date_#{i}",
        "#{Period.table_name}.organization_id = :organization_id_#{i}",
      ].join(' AND ')
    end

    fix_conditions = [
      'state = :state',
      'final = :boolean_false',
      'notification_level = :notification_level'
    ].join(' AND ')

    includes(:control_objective_item => { :review => :period }).where(
      [
        "(#{pre_conditions.map { |c| "(#{c})" }.join(' OR ')})", fix_conditions
      ].join(' AND '),
      parameters
    )
  }
  scope :unconfirmed_and_stale, lambda {
    stale_parameters = Organization.all_parameters(
      :admin_finding_stale_confirmed_days)
    pre_conditions = []
    parameters = {
      :state => STATUS[:unconfirmed],
      :boolean_false => false
    }

    stale_parameters.each_with_index do |stale_parameter, i|
      stale_days = stale_parameter[:parameter].to_i
      parameters[:"stale_unconfirmed_date_#{i}"] =
        (FINDING_STALE_UNCONFIRMED_DAYS + stale_days).days.ago_in_business.to_date
      parameters[:"organization_id_#{i}"] = stale_parameter[:organization].id

      pre_conditions << [
        "first_notification_date < :stale_unconfirmed_date_#{i}",
        "#{Period.table_name}.organization_id = :organization_id_#{i}",
      ].join(' AND ')
    end

    fix_conditions = [
      'state = :state',
      'final = :boolean_false'
    ].join(' AND ')

    includes(:control_objective_item => { :review => :period }).where(
      [
        "(#{pre_conditions.map { |c| "(#{c})" }.join(' OR ')})", fix_conditions
      ].join(' AND '),
      parameters
    )
  }
  scope :confirmed_and_stale, lambda {
    stale_parameters = Organization.all_parameters(
      :admin_finding_stale_confirmed_days)
    pre_conditions = []
    parameters = {
      :state => STATUS[:confirmed],
      :boolean_false => false,
      :notification_level => 0
    }

    stale_parameters.each_with_index do |stale_parameter, i|
      stale_days = stale_parameter[:parameter].to_i
      parameters[:"stale_confirmed_date_#{i}"] =
        stale_days.days.ago_in_business.to_date
      parameters[:"stale_first_notification_date_#{i}"] =
        (FINDING_STALE_UNCONFIRMED_DAYS + stale_days).days.ago_in_business.to_date
      parameters[:"organization_id_#{i}"] = stale_parameter[:organization].id

      pre_conditions << [
        [
          "confirmation_date < :stale_confirmed_date_#{i}",
          "first_notification_date < :stale_first_notification_date_#{i}"
        ].join(' OR '),
        "#{Period.table_name}.organization_id = :organization_id_#{i}",
      ].map {|c| "(#{c})"}.join(' AND ')
    end

    fix_conditions = [
      'state = :state',
      'final = :boolean_false',
      'notification_level = :notification_level'
    ].join(' AND ')

    includes(
      :finding_answers, {:control_objective_item => {:review => :period}}
    ).where(
      [
        "(#{pre_conditions.map { |c| "(#{c})" }.join(' OR ')})", fix_conditions
      ].join(' AND '),
      parameters
    )
  }
  scope :being_implemented, where({:state => STATUS[:being_implemented]})
  scope :list_all_by_date, lambda { |from_date, to_date, order|
    includes(
      :control_objective_item => {:review =>
          [:period, :conclusion_final_review, {:plan_item => :business_unit}]}
    ).where(
      [
        "#{ConclusionReview.table_name}.issue_date BETWEEN :begin AND :end",
        "#{Period.table_name}.organization_id = :organization_id",
        'state IN (:states)'
      ].join(' AND '),
      {
        :begin => from_date, :end => to_date,
        :organization_id => GlobalModelConfig.current_organization_id,
        :states => STATUS.except(*EXCLUDE_FROM_REPORTS_STATUS).values
      }
    ).order(
      order ?
        ["#{Period.table_name}.start ASC", "#{Period.table_name}.end ASC"] : nil
    )
  }
  scope :list_all_in_execution_by_date, lambda { |from_date, to_date|
    includes(
      :control_objective_item => {:review => [:period, :conclusion_final_review]}
    ).where(
      [
        "#{Review.table_name}.created_at BETWEEN :begin AND :end",
        "#{Period.table_name}.organization_id = :organization_id",
        "#{ConclusionFinalReview.table_name}.review_id IS NULL"
      ].join(' AND '),
      {
        :begin => from_date, :end => to_date,
        :organization_id => GlobalModelConfig.current_organization_id
      }
    )
  }
  scope :internal_audit, includes(
    :control_objective_item => {
      :review => {:plan_item => {:business_unit => :business_unit_type}}
    }
  ).where("#{BusinessUnitType.table_name}.external" => false)
  scope :external_audit, includes(
    :control_objective_item => {
      :review => {:plan_item => {:business_unit => :business_unit_type}}
    }
  ).where("#{BusinessUnitType.table_name}.external" => true)

  # Restricciones sobre los atributos
  attr_protected :first_notification_date, :final
  attr_readonly :review_code
  # Atributos no persistente
  attr_accessor :nested_user, :finding_prefix, :avoid_changes_notification,
    :users_for_notification, :user_who_make_it, :nested_finding_relation

  # Callbacks
  before_create :can_be_created?
  before_save :can_be_modified?, :check_users_for_notification
  before_destroy :can_be_destroyed?
  after_update :notify_changes_to_users
  before_validation :set_proper_parent

  # Restricciones
  validates :control_objective_item_id, :description, :review_code,
    :presence => true
  validates :review_code, :type, :length => {:maximum => 255},
    :allow_nil => true, :allow_blank => true
  validates :control_objective_item_id,
    :numericality => {:only_integer => true},
    :allow_nil => true, :allow_blank => true
  validates_date :first_notification_date, :allow_nil => true
  validates_date :follow_up_date, :solution_date, :origination_date,
    :allow_nil => true, :allow_blank => true
  validates_each :follow_up_date, :unless => :incomplete? do |record, attr, value|
    check_for_blank = record.kind_of?(Weakness) && (record.being_implemented? ||
        record.implemented? || record.implemented_audited?)

    record.errors.add attr, :blank if check_for_blank && value.blank?
    record.errors.add attr, :must_be_blank if !check_for_blank && !value.blank?
  end
  validates_each :solution_date, :unless => :incomplete? do |record, attr, value|
    check_for_blank = record.implemented_audited? || record.assumed_risk?

    record.errors.add attr, :blank if check_for_blank && value.blank?
    record.errors.add attr, :must_be_blank if !check_for_blank && !value.blank?
  end
  validates_each :answer do |record, attr, value|
    check_for_blank = record.being_implemented? ||
      (record.state_changed? && record.state_was == STATUS[:confirmed])

    record.errors.add attr, :blank if check_for_blank && value.blank?
  end
  validates_each :state do |record, attr, value|
    if value && record.state_changed? &&
        !record.next_status_list(record.state_was).values.include?(value)
      record.errors.add attr, :inclusion
    end

    record.errors.add attr, :must_have_a_comment if record.must_have_a_comment?
    
    if record.implemented_audited? && record.work_papers.empty?
      record.errors.add attr, :must_have_a_work_paper
    end
  end
  validates_each :review_code do |record, attr, value|
    review = record.control_objective_item.try(:review)

    if review
      (review.weaknesses | review.oportunities).each do |finding|
        another_record = (!record.new_record? && finding.id != record.id) ||
          (record.new_record? && finding.object_id != record.object_id)

        if value == finding.review_code && another_record &&
            (record.final == finding.final)
          record.errors.add attr, :taken
        end
      end
    end
  end
  validates_each :finding_user_assignments do |record, attr, value|
    users = value.reject(&:marked_for_destruction?).map(&:user)

    unless users.any?(&:can_act_as_audited?) && users.any?(&:auditor?) &&
        users.any?(&:supervisor?) && users.any?(&:manager?)
      record.errors.add attr, :invalid
    end
  end

  # Relaciones
  belongs_to :control_objective_item
  has_one :review, :through => :control_objective_item
  has_one :control_objective, :through => :control_objective_item,
    :class_name => 'ControlObjective'
  has_many :finding_answers, :dependent => :destroy,
    :after_add => :answer_added, :order => 'created_at ASC'
  has_many :notification_relations, :as => :model, :dependent => :destroy
  has_many :finding_relations, :dependent => :destroy,
    :before_add => :check_for_valid_relation
  has_many :notifications, :through => :notification_relations, :uniq => true,
    :order => 'created_at'
  has_many :costs, :as => :item, :dependent => :destroy
  has_many :work_papers, :as => :owner, :dependent => :destroy,
    :before_add => [:prepare_work_paper, :check_for_final_review],
    :before_remove => :check_for_final_review, :order => 'created_at ASC'
  has_many :comments, :as => :commentable, :dependent => :destroy,
    :order => 'created_at ASC'
  has_many :finding_user_assignments, :include => :user, :inverse_of => :finding
  has_many :finding_review_assignments, :dependent => :destroy,
    :inverse_of => :finding
  has_many :users, :through => :finding_user_assignments,
    :order => 'last_name ASC, name ASC'
  
  accepts_nested_attributes_for :finding_answers, :allow_destroy => false
  accepts_nested_attributes_for :finding_relations, :allow_destroy => true
  accepts_nested_attributes_for :work_papers, :allow_destroy => true
  accepts_nested_attributes_for :costs, :allow_destroy => false
  accepts_nested_attributes_for :comments, :allow_destroy => false
  accepts_nested_attributes_for :finding_user_assignments,
    :allow_destroy => true

  def initialize(attributes = nil, import_users = false)
    super(attributes)

    if import_users && self.try(:control_objective_item).try(:review)
      self.control_objective_item.review.review_user_assignments.map do |rua|
        self.finding_user_assignments.build(:user_id => rua.user_id)
      end
    end

    if self.control_objective_item.try(:control)
      self.effect ||= self.control_objective_item.control.effects
    end

    self.state ||= STATUS[:incomplete]
    self.final ||= false
    self.finding_prefix ||= false
  end

  def self.columns_for_sort
    HashWithIndifferentAccess.new({
      :risk_asc => {
        :name => "#{Finding.human_attribute_name(:risk)} (#{I18n.t(:'label.ascendant')})",
        :field => [
          "#{Finding.table_name}.risk ASC",
          "#{Finding.table_name}.state ASC"
        ]
      },
      :risk_desc => {
        :name => "#{Finding.human_attribute_name(:risk)} (#{I18n.t(:'label.descendant')})",
        :field => [
          "#{Finding.table_name}.risk DESC",
          "#{Finding.table_name}.state ASC"
        ]
      },
      :state => {
        :name => Finding.human_attribute_name(:state),
        :field => "#{Finding.table_name}.state ASC"
      },
      :review => {
        :name => Review.model_name.human,
        :field => "#{Review.table_name}.identification ASC"
      }
    })
  end

  def <=>(other)
    other.kind_of?(Finding) ? self.id <=> other.id : -1
  end

  def to_s
    "#{self.review_code} - #{self.control_objective_item.try(:review)}"
  end

  def check_for_final_review(_)
    if self.final? && self.review && self.review.is_frozen?
      raise 'Conclusion Final Review frozen'
    end
  end

  def set_proper_parent
    self.finding_answers.each { |fa| fa.finding = self }
    self.finding_relations.each { |fr| fr.finding = self }
    self.finding_user_assignments.each { |fua| fua.finding = self }
    self.work_papers.each { |wp| wp.owner = self }
  end

  def check_for_valid_relation(finding_relation)
    related_finding = finding_relation.related_finding
    
    if related_finding && (related_finding.final? ||
          (!related_finding.is_in_a_final_review? &&
            related_finding.review.id != self.control_objective_item.try(:review_id)))
      raise 'Invalid finding for asociation'
    end
  end

  def organization
    self.review.try(:organization)
  end

  def prepare_work_paper(work_paper)
    work_paper.code_prefix ||= self.get_parameter(
      :admin_code_prefix_for_work_papers_in_weaknesses_follow_up)
  end

  def answer_added(finding_answer)
    if (self.unconfirmed? || self.notify?) &&
        finding_answer.user.try(:can_act_as_audited?)
      self.confirmed! finding_answer.user
    end
  end

  def notify_changes_to_users
    if !self.incomplete? && !self.avoid_changes_notification
      added = self.finding_user_assignments.select(&:new_record?).map(&:user)
      removed = self.finding_user_assignments.select(
        &:marked_for_destruction?).map(&:user)

      if !added.blank? && !removed.blank?
        Notifier.reassigned_findings_notification(added, removed, self,
          false).deliver
      elsif added.blank? && !removed.blank?
        title = I18n.t(:'finding.responsibility_removed',
          :class_name => self.class.model_name.human.downcase,
          :review_code => self.review_code,
          :review => self.review.try(:identification))

        Notifier.changes_notification(removed, :title => title).deliver
      end
    end
  end

  def can_be_modified?
    if self.final == false || self.final_changed? ||
        (!self.changed? && !self.control_objective_item.review.is_frozen?)
      true
    else
      msg = I18n.t(:'finding.readonly')

      if !self.errors.full_messages.include?(msg)
        self.errors.add :base, msg
      end

      false
    end
  end

  def can_be_created?
    unless self.is_in_a_final_review? &&
        (self.changed? || self.marked_for_destruction?)
      true
    else
      msg = I18n.t(:'finding.readonly')
      self.errors.add :base, msg unless self.errors.full_messages.include?(msg)

      false
    end
  end

  def can_be_destroyed?
    self.is_in_a_final_review? ? false : true
  end

  def is_in_a_final_review?
    self.control_objective_item.try(:review).try(:has_final_review?)
  end

  def check_users_for_notification
    if !self.incomplete? &&
        !(self.users_for_notification || []).reject(&:blank?).empty?
      
      self.users_for_notification.reject(&:blank?).uniq.each do |user_id|
        finding_user_assignment = self.finding_user_assignments.detect do |fua|
          fua.user_id == user_id.to_i
        end

        if finding_user_assignment
          user = self.users.detect {|u| u.id == user_id.to_i} ||
            User.find(user_id)
          
          Notifier.notify_new_finding(user, self).deliver
        end
      end
    end
  end

  def must_have_a_comment?
    self.being_implemented? && self.was_implemented? &&
      !self.comments.detect { |c| c.new_record? && c.valid? }
  end

  def mark_as_unconfirmed!
    self.first_notification_date = Date.today unless self.unconfirmed?
    self.state = STATUS[:unconfirmed] if self.notify?

    self.save(:validate => false)

  rescue ActiveRecord::StaleObjectError
    self.review.reload
    self.save(:validate => false)
  end

  def confirmed!(user = nil)
    if self.unconfirmed? || self.notify?
      self.update_attribute :state, STATUS[:confirmed]

      if self.confirmation_date.blank?
        self.update_attribute :confirmation_date, Date.today
      end

      if user
        self.notifications.not_confirmed.each do |notification|
          if notification.user.can_act_as_audited?
            notification.update_attributes!(
              :status => Notification::STATUS[:confirmed],
              :confirmation_date => notification.confirmation_date || Time.now,
              :user_who_confirm => user
            )
          end
        end
      end
    end
  end

  STATUS.each do |status_type, status_value|
    define_method("#{status_type}?") { self.state == status_value }
  end

  STATUS.each do |status_type, status_value|
    define_method("was_#{status_type}?") { self.state_was == status_value }
  end

  def state_text
    self.state ? I18n.t("finding.status_#{STATUS.invert[self.state]}") : '-'
  end
  
  def stale?
    self.being_implemented? && self.follow_up_date &&
      self.follow_up_date < Time.now.to_date
  end

  def pending?
    PENDING_STATUS.include?(self.state)
  end

  def has_audited?
    self.finding_user_assignments.any? do |fua|
      !fua.marked_for_destruction? && fua.user.can_act_as_audited?
    end
  end

  def has_auditor?
    self.finding_user_assignments.any? do |fua|
      !fua.marked_for_destruction? && fua.user.auditor?
    end
  end

  def cost
    self.costs.reject(&:new_record?).sum(&:cost)
  end

  def issue_date
    self.review.try(:conclusion_final_review).try(:issue_date)
  end

  def important_dates
    important_dates = []

    if self.first_notification_date
      important_dates << I18n.t(:'finding.important_dates.notification_date',
        :date => I18n.l(self.first_notification_date, :format => :long).strip)
    end

    if self.confirmation_date
      important_dates << I18n.t(:'finding.important_dates.confirmation_date',
        :date => I18n.l(self.confirmation_date, :format => :long).strip)
    end

    if self.confirmed? || self.unconfirmed?
      if self.confirmation_date
        max_notification_date = self.stale_confirmed_days.days.
          ago_in_business.to_date
        expiration_diff = self.confirmation_date.try(:diff_in_business,
          max_notification_date)
      else
        max_notification_date = (FINDING_STALE_UNCONFIRMED_DAYS +
            self.stale_confirmed_days).days.ago_in_business.to_date
        expiration_diff = self.first_notification_date.try(:diff_in_business,
          max_notification_date)
      end

      if expiration_diff && expiration_diff >= 0
        important_dates << I18n.t(:'finding.important_dates.expiration_date',
          :date => I18n.l(expiration_diff.days.from_now_in_business.to_date,
            :format => :long).strip)
      end
    end

    important_dates
  end

  def stale_confirmed_days
    self.parameter_in(self.review.organization.id,
      :admin_finding_stale_confirmed_days).to_i
  end

  def next_status_list(state = nil)
    state_key = STATUS.invert[state || self.state]
    allowed_keys = STATUS_TRANSITIONS[state_key]

    STATUS.reject {|k,| !allowed_keys.include?(k)}
  end
  
  def versions_between(start_date = nil, end_date = nil)
    conditions = []
    conditions << 'created_at >= :filter_start' if start_date
    conditions << 'created_at <= :filter_end' if end_date
    conditions.blank? ? self.versions : self.versions.where(
      conditions.join(' AND '),
      {:filter_start => start_date, :filter_end => end_date}
    )
  end

  def versions_after_final_review(end_date = nil)
    self.versions_between(self.control_objective_item.try(:review).try(
        :conclusion_final_review).try(:created_at), end_date)
  end

  def versions_before_final_review(start_date = nil)
    self.versions_between(start_date, self.control_objective_item.try(
        :review).try(:conclusion_final_review).try(:created_at))
  end

  def status_change_history
    last_state = nil
    findings_with_status_changed = []

    self.versions.each do |version|
      finding = version.reify

      if finding && finding.state != last_state
        last_state = finding.state

        if version.previous.try(:whodunnit)
          finding.user_who_make_it = User.find(version.previous.whodunnit)
        end
        
        findings_with_status_changed << finding
      end
    end

    findings_with_status_changed << self if last_state != self.state

    findings_with_status_changed
  end

  def users_for_scaffold_notification(level = 1)
    users = self.finding_user_assignments.map(&:user).select(
      &:can_act_as_audited?)
    highest_users = users.reject {|u| u.ancestors.any? {|p| users.include?(p)}}
    level_overflow = false

    level.times do
      users |= (highest_users = highest_users.map(&:parent).compact.uniq)
      level_overflow ||= highest_users.empty?
    end

    level_overflow ? [] : users.uniq
  end

  def manager_users_for_level(level = 1)
    users = self.finding_user_assignments.map(&:user).select(
      &:can_act_as_audited?)
    highest_users = users.reject {|u| u.ancestors.any? {|p| users.include?(p)}}

    level.times { highest_users = highest_users.map(&:parent).compact.uniq }

    highest_users.reject { |u| self.users.include?(u) }
  end

  def notification_date_for_level(level = 1)
    date_for_notification = self.first_notification_date.try(:dup) || Date.today
    days_to_add = (self.stale_confirmed_days +
        self.stale_confirmed_days * level).next

    until days_to_add == 0
      date_for_notification += 1
      days_to_add -= 1 unless [0, 6].include?(date_for_notification.wday)
    end

    date_for_notification
  end

  def commitment_date
    self.finding_answers.where('commitment_date IS NOT NULL').first.try(
      :commitment_date)
  end

  def to_pdf(organization = nil)
    pdf = PDF::Writer.create_generic_pdf(:portrait, false)

    pdf.add_review_header organization, self.review.identification.strip,
      self.review.plan_item.project.strip

    pdf.move_pointer PDF_FONT_SIZE * 3

    pdf.add_title self.class.model_name.human, (PDF_FONT_SIZE * 1.5).round, :center,
      false

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_title "<b>#{self.class.human_attribute_name(:review_code)}</b>: " +
      self.review_code, PDF_FONT_SIZE, :center, false

    pdf.start_new_page

    pdf.move_pointer((PDF_FONT_SIZE * 2.5).round)

    pdf.add_description_item(
      self.class.human_attribute_name('control_objective_item_id'),
      self.control_objective_item.control_objective_text, 0, false)
    pdf.add_description_item(self.class.human_attribute_name('review_code'),
      self.review_code, 0, false)
    pdf.add_description_item(self.class.human_attribute_name('description'),
      self.description, 0, false)

    pdf.move_pointer((PDF_FONT_SIZE * 2.5).round)

    if self.kind_of?(Weakness)
      pdf.add_description_item(Weakness.human_attribute_name('risk'),
        self.risk_text, 0, false)
      pdf.add_description_item(Weakness.human_attribute_name('priority'),
        self.priority_text, 0, false)
      pdf.add_description_item(Weakness.human_attribute_name('effect'),
        self.effect, 0, false)
      pdf.add_description_item(Weakness.human_attribute_name(
          'audit_recommendations'), self.audit_recommendations, 0, false)
    end

    pdf.add_description_item(self.class.human_attribute_name('answer'),
      self.answer, 0, false) unless self.unanswered?

    if self.kind_of?(Weakness) && (self.implemented? || self.being_implemented?)
      pdf.add_description_item(Weakness.human_attribute_name('follow_up_date'),
        (I18n.l(self.follow_up_date, :format => :long) if self.follow_up_date),
        0, false)
    end

    if self.implemented_audited?
      pdf.add_description_item(self.class.human_attribute_name('solution_date'),
        (I18n.l(self.solution_date, :format => :long) if self.solution_date), 0,
        false)
    end

    audited = self.users.select { |u| u.can_act_as_audited? }.map(&:full_name)

    pdf.add_description_item(self.class.human_attribute_name('user_ids'),
      audited.join('; '), 0, false)

    pdf.add_description_item(self.class.human_attribute_name('audit_comments'),
      self.audit_comments, 0, false)

    pdf.add_description_item(self.class.human_attribute_name('state'),
      self.state_text, 0, false)

    unless self.work_papers.blank?
      pdf.start_new_page
      pdf.move_pointer PDF_FONT_SIZE * 3

      pdf.add_title(ControlObjectiveItem.human_attribute_name('work_papers'),
        (PDF_FONT_SIZE * 1.5).round, :center, false)
      pdf.add_title("#{self.class.model_name.human} #{self.review_code}",
        (PDF_FONT_SIZE * 1.5).round, :center, false)

      pdf.move_pointer PDF_FONT_SIZE * 3

      self.work_papers.each do |wp|
        pdf.text wp.inspect, :justification => :center,
          :font_size => PDF_FONT_SIZE
      end
    else
      pdf.add_footnote(I18n.t(:'finding.without_work_papers'))
    end

    pdf.custom_save_as(self.pdf_name, self.class.table_name, self.id)
  end

  def absolute_pdf_path
    PDF::Writer.absolute_path(self.pdf_name, self.class.table_name, self.id)
  end

  def relative_pdf_path
    PDF::Writer.relative_path(self.pdf_name, self.class.table_name, self.id)
  end

  def pdf_name
    ("#{self.class.model_name.human.downcase.gsub(/\s+/, '_')}-" +
      "#{self.review_code}.pdf").sanitized_for_filename
  end

  def follow_up_pdf(organization = nil)
    pdf = PDF::Writer.create_generic_pdf(:portrait)
    issue_date = self.issue_date ? I18n.l(self.issue_date, :format => :long) :
      I18n.t(:'finding.without_conclusion_final_review')

    add_finding_follow_up_header pdf, organization
    
    pdf.add_title I18n.t("finding.follow_up_report.#{self.class.name.downcase}"+
        '.title'), (PDF_FONT_SIZE * 1.25).round, :center

    pdf.move_pointer((PDF_FONT_SIZE * 1.25).round)

    pdf.add_title I18n.t("finding.follow_up_report.#{self.class.name.downcase}"+
        '.subtitle'), (PDF_FONT_SIZE * 1.25).round, :left

    pdf.move_pointer((PDF_FONT_SIZE * 1.25).round)

    pdf.add_description_item(Review.model_name.human,
      "#{self.review.long_identification} (#{issue_date})", 0, false)
    pdf.add_description_item(Finding.human_attribute_name(:review_code),
      self.review_code, 0, false)
    
    pdf.add_description_item(ProcessControl.model_name.human,
      self.control_objective_item.process_control.name, 0, false)
    pdf.add_description_item(Finding.human_attribute_name(
        :control_objective_item_id),
      self.control_objective_item.control_objective_text, 0, false)
    pdf.add_description_item(self.class.human_attribute_name(:description),
      self.description, 0, false)
    pdf.add_description_item(self.class.human_attribute_name(:state),
      self.state_text, 0, false)

    if self.kind_of?(Weakness)
      pdf.add_description_item(self.class.human_attribute_name(:risk),
        self.risk_text, 0, false)
      pdf.add_description_item(self.class.human_attribute_name(:priority),
        self.priority_text, 0, false)
      pdf.add_description_item(Finding.human_attribute_name(:effect),
        self.effect, 0, false)
      pdf.add_description_item(Finding.human_attribute_name(
          :audit_recommendations), self.audit_recommendations, 0, false)
    end
    
    pdf.add_description_item(Finding.human_attribute_name(:answer),
      self.answer, 0, false)

    if self.kind_of?(Weakness) && self.follow_up_date
      pdf.add_description_item(Finding.human_attribute_name(:follow_up_date),
        I18n.l(self.follow_up_date, :format => :long), 0, false)
    end

    if self.solution_date
      pdf.add_description_item(Finding.human_attribute_name(:solution_date),
        I18n.l(self.solution_date, :format => :long), 0, false)
    end

    pdf.add_description_item(Finding.human_attribute_name(:audit_comments),
      self.audit_comments, 0, false)

    audited, auditors = *self.users.partition(&:can_act_as_audited?)

    pdf.add_title I18n.t(:'finding.auditors', :count => auditors.size),
      PDF_FONT_SIZE, :left
    pdf.add_list auditors.map(&:full_name), PDF_FONT_SIZE * 2

    pdf.add_title I18n.t(:'finding.responsibles', :count => audited.size),
      PDF_FONT_SIZE, :left
    pdf.add_list audited.map(&:full_name), PDF_FONT_SIZE * 2
    
    important_attributes = [:state, :risk, :priority, :follow_up_date]
    important_changed_versions = [Version.new]
    previous_version = self.versions.first

    while (previous_version.try(:event) &&
          last_checked_version = (previous_version.try(:next) ||
            Version.new(:object => object_to_string(self))))
      has_important_changes = important_attributes.any? do |attribute|
        current_value = last_checked_version.reify ?
          last_checked_version.reify.send(attribute) : nil
        old_value = previous_version.reify ?
          previous_version.reify.send(attribute) : nil

        current_value != old_value &&
          !(current_value.blank? && old_value.blank?)
      end

      if has_important_changes
        important_changed_versions << last_checked_version
      end

      previous_version = last_checked_version
    end

    pdf.add_title I18n.t(:'finding.change_history'),
      (PDF_FONT_SIZE * 1.25).round, :full

    if important_changed_versions.size > 1
      last_checked_version = self.versions.first
      column_names = {'attribute' => 30, 'old_value' => 35, 'new_value' => 35}
      columns, column_data = {}, []

      column_names.each do |col_name, col_size|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = col_name == 'attribute' ?
            '' : I18n.t("version.column_#{col_name}")
          c.justification = :full
          c.width = pdf.percent_width(col_size)
        end
      end

      previous_version = important_changed_versions.shift
      previous_finding = previous_version.reify

      important_changed_versions.each do |version|
        version_finding = version.reify
        column_data = []

        important_attributes.each do |attribute|
          previous_method_name = previous_finding.respond_to?(
            "#{attribute}_text") ? "#{attribute}_text".to_sym : attribute
          version_method_name = version_finding.respond_to?(
           "#{attribute}_text") ? "#{attribute}_text".to_sym : attribute

          column_data << {
            'attribute' => Finding.human_attribute_name(attribute).to_iso,
            'old_value' => previous_finding.try(:send, previous_method_name).
              to_translated_string.to_iso,
            'new_value' => version_finding.try(:send, version_method_name).
              to_translated_string.to_iso
          }
        end

        unless column_data.blank?
          pdf.move_pointer PDF_FONT_SIZE
          
          pdf.add_description_item(Version.human_attribute_name(:created_at),
            I18n.l(version.created_at || version_finding.updated_at,
              :format => :long))
          pdf.add_description_item(User.model_name.human,
            version.previous.try(:whodunnit) ?
              User.find(version.previous.whodunnit).try(:full_name) : nil
          )

          pdf.move_pointer PDF_FONT_SIZE

          PDF::SimpleTable.new do |table|
            table.width = pdf.page_usable_width
            table.columns = columns
            table.data = column_data
            table.column_order = ['attribute', 'old_value', 'new_value']
            table.split_rows = true
            table.row_gap = (PDF_FONT_SIZE * 0.75).round
            table.font_size = (PDF_FONT_SIZE * 0.75).round
            table.shade_rows = :none
            table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
            table.heading_font_size = (PDF_FONT_SIZE * 0.75).round
            table.shade_headings = true
            table.position = :left
            table.orientation = :right
            table.show_lines = :all
            table.inner_line_style = PDF::Writer::StrokeStyle.new(0.5)
            table.render_on pdf
          end
        end

        previous_finding = version_finding
        previous_version = version
      end
    else
      pdf.text(
        "\n#{I18n.t(:'finding.follow_up_report.without_important_changes')}",
        :font_size => PDF_FONT_SIZE)
    end

    unless self.comments.blank?
      column_names = {'comment' => 50, 'user_id' => 30, 'created_at' => 20}
      columns, column_data = {}, []

      column_names.each do |col_name, col_size|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = Comment.human_attribute_name col_name
          c.justification = :full
          c.width = pdf.percent_width(col_size)
        end
      end

      self.comments.each do |comment|
        column_data << {
          'comment' => comment.comment.try(:to_iso),
          'user_id' => comment.user.try(:full_name).try(:to_iso),
          'created_at' => I18n.l(comment.created_at,
            :format => :validation).to_iso
        }
      end

      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_title I18n.t(:'finding.comments'), (PDF_FONT_SIZE * 1.25).round,
        :full

      pdf.move_pointer PDF_FONT_SIZE

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = ['user_id', 'comment', 'created_at']
          table.split_rows = true
          table.row_gap = (PDF_FONT_SIZE * 0.75).round
          table.font_size = PDF_FONT_SIZE
          table.shade_rows = :none
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.show_lines = :all
          table.inner_line_style = PDF::Writer::StrokeStyle.new(0.5)
          table.render_on pdf
        end
      end
    end

    unless self.work_papers.blank?
      column_names = {'name' => 20, 'code' => 20, 'number_of_pages' => 20,
        'description' => 40}
      columns, column_data = {}, []

      column_names.each do |col_name, col_size|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = WorkPaper.human_attribute_name col_name
          c.justification = :full
          c.width = pdf.percent_width(col_size)
        end
      end

      self.work_papers.each do |work_paper|
        column_data << {
          'name' => work_paper.name.try(:to_iso),
          'code' => work_paper.code.try(:to_iso),
          'number_of_pages' => work_paper.number_of_pages || '-',
          'description' => work_paper.description.try(:to_iso)
        }
      end

      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_title I18n.t(:'finding.follow_up_report.work_papers'),
        (PDF_FONT_SIZE * 1.25).round, :full

      pdf.move_pointer PDF_FONT_SIZE

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = ['name', 'code', 'number_of_pages',
            'description']
          table.split_rows = true
          table.row_gap = (PDF_FONT_SIZE * 0.75).round
          table.font_size = PDF_FONT_SIZE
          table.shade_rows = :none
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.show_lines = :all
          table.inner_line_style = PDF::Writer::StrokeStyle.new(0.5)
          table.render_on pdf
        end
      end
    end

    unless self.finding_answers.blank?
      column_names = {'answer' => 50, 'user_id' => 30, 'created_at' => 20}
      columns, column_data = {}, []

      column_names.each do |col_name, col_size|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = FindingAnswer.human_attribute_name col_name
          c.justification = :full
          c.width = pdf.percent_width(col_size)
        end
      end

      self.finding_answers.each do |finding_answer|
        column_data << {
          'answer' => finding_answer.answer.try(:to_iso),
          'user_id' => finding_answer.user.try(:full_name).try(:to_iso),
          'created_at' => I18n.l(finding_answer.created_at,
            :format => :validation).to_iso
        }
      end

      pdf.move_pointer PDF_FONT_SIZE
      
      pdf.add_title I18n.t(:'finding.follow_up_report.follow_up_comments'),
        (PDF_FONT_SIZE * 1.25).round, :full
      
      pdf.move_pointer PDF_FONT_SIZE

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = ['user_id', 'answer', 'created_at']
          table.split_rows = true
          table.row_gap = (PDF_FONT_SIZE * 0.75).round
          table.font_size = PDF_FONT_SIZE
          table.shade_rows = :none
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.show_lines = :all
          table.inner_line_style = PDF::Writer::StrokeStyle.new(0.5)
          table.render_on pdf
        end
      end
    end

    pdf.custom_save_as self.follow_up_pdf_name, Finding.table_name, self.id
  end

  def absolute_follow_up_pdf_path
    PDF::Writer.absolute_path self.follow_up_pdf_name, Finding.table_name,
      self.id
  end

  def relative_follow_up_pdf_path
    PDF::Writer.relative_path self.follow_up_pdf_name, Finding.table_name,
      self.id
  end

  def follow_up_pdf_name
    code = self.review_code.sanitized_for_filename

    I18n.t(:'finding.follow_up_report.pdf_name', :code => code)
  end

  def self.notify_for_unconfirmed_for_notification_findings
    # Sólo si no es sábado o domingo
    unless [0, 6].include?(Date.today.wday)
      Finding.transaction do
        users = Finding.unconfirmed_for_notification.inject([]) do |u, finding|
          u | finding.users.select do |user|
            user.notifications.not_confirmed.any? do |n|
              n.findings.include?(finding)
            end
          end
        end

        users.each { |user| Notifier.stale_notification(user).deliver }
      end
    end
  end

  def self.mark_as_unanswered_if_necesary
    # Sólo si no es sábado o domingo (porque no tiene sentido)
    unless [0, 6].include?(Date.today.wday)
      Finding.transaction do
        findings = Finding.confirmed_and_stale.reject do |finding|
          finding.finding_answers.detect { |fa| fa.user.can_act_as_audited? }
        end

        findings |= Finding.unconfirmed_and_stale.reject do |finding|
          finding.finding_answers.detect { |fa| fa.user.can_act_as_audited? }
        end

        users = findings.inject([]) do |u, finding|
          finding.update_attribute :state, Finding::STATUS[:unanswered]
          u | finding.users
        end

        users.each do |user|
          Notifier.unanswered_findings_notification(user,
            findings.select { |f| f.users.include?(user) }).deliver
        end
      end
    end
  end

  def self.notify_manager_if_necesary
    # Sólo si no es sábado o domingo (porque no tiene sentido)
    unless [0, 6].include?(Date.today.wday)
      Finding.transaction do
        n = 0

        until (findings = Finding.unanswered_and_stale(n += 1)).empty?
          findings.each do |finding|
            users = finding.users_for_scaffold_notification(n)

            # No notificar si no hace falta
            unless users.empty?
              Notifier.unanswered_finding_to_manager_notification(finding,
                users | finding.users, n).deliver
            end

            finding.update_attribute :notification_level, users.empty? ? -1 : n
          end
        end
      end
    end
  end

  def self.warning_users_about_expiration
    # Sólo si no es sábado o domingo (porque no tiene sentido)
    unless [0, 6].include?(Date.today.wday)
      users = Finding.next_to_expire.inject([]) do |u, finding|
        u | finding.users.select { |u| u.can_act_as_audited? }
      end

      users.each do |user|
        Notifier.findings_expiration_warning(user,
          user.findings.next_to_expire).deliver
      end
    end
  end

  private

  def add_finding_follow_up_header(pdf, organization, date = Date.today)
    pdf.open_object do |heading|
      font_size = PDF_FONT_SIZE
      font_height_size = pdf.font_height(font_size)
      y_top = pdf.page_height - (pdf.top_margin / 2)

      if organization.try(:image_model) &&
          File.exists?(organization.image_model.image.path(:thumb))
        pdf.add_image_from_file(
          organization.image_model.image.path(:thumb),
          pdf.left_margin, pdf.absolute_top_margin + font_height_size,
          organization.image_model.image_geometry(:pdf_thumb)[:width],
          organization.image_model.image_geometry(:pdf_thumb)[:height])
      end

      date_text = I18n.l(date, :format => :long) if date
      text = I18n.t :'finding.follow_up_report.print_date', :date => date_text
      x_start = pdf.absolute_right_margin - pdf.text_width(text, font_size)
      pdf.add_text(x_start, y_top, text.to_iso, font_size)

      pdf.close_object
      pdf.add_object(heading, :all_pages)
    end
  end
end