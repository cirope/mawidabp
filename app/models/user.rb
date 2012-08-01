# -*- coding: utf-8 -*-
require 'digest/sha2'

class User < ActiveRecord::Base
  include ParameterSelector
  include Comparable
  include Trimmer

  trimmed_fields :user, :email, :name, :last_name

  # Constantes
  COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new(
    :user => {
      :column => "LOWER(#{table_name}.user)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :name => {
      :column => "LOWER(#{table_name}.name)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :last_name => {
      :column => "LOWER(#{table_name}.last_name)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :function => {
      :column => "LOWER(#{table_name}.function)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    }
  )

  has_paper_trail :ignore => [:last_access, :logged_in], :meta => {
    :organization_id => lambda { GlobalModelConfig.current_organization_id },
    :important => lambda { |user| user.is_an_important_change }
  }
  acts_as_tree :foreign_key => 'manager_id', :readonly => true,
    :order => 'last_name ASC, name ASC', :dependent_children => :nullify

  # Atributos protegidos
  attr_protected :group_admin

  # Atributos no persistentes
  attr_accessor :user_data, :send_notification_email, :roles_changed,
    :reallocation_errors, :nested_user

  # Alias de atributos
  alias_attribute :informal, :user

  # Named scopes
  scope :list, lambda {
    includes(:organizations).where(
      :organizations => { :id => GlobalModelConfig.current_organization_id }
    )
  }
  scope :with_valid_confirmation_hash, lambda { |confirmation_hash|
    where(
      [
        'change_password_hash = :confirmation_hash', 'hash_changed > :time'
      ].join(' AND '),
      {
        :confirmation_hash => confirmation_hash,
        :time => BLANK_PASSWORD_STALE_DAYS.days.ago,
      }
    ).limit(1)
  }
  scope :all_with_findings_for_notification, includes(
    :finding_user_assignments => :raw_finding
  ).where(
    :findings => {:state => Finding::STATUS[:notify], :final => false}
  ).order(["#{table_name}.last_name ASC", "#{table_name}.name ASC"])

  # Callbacks
  before_destroy :has_not_orphan_fingings?
  before_validation :inject_auth_privileges_in_roles, :set_proper_parent
  before_update :check_roles_changes
  after_update :log_password_change
  after_save :reset_to_important_change

  # Restricciones
  validates :name, :last_name, :format => {:with => /\A\w[\w\s]*\z/},
    :allow_nil => true, :allow_blank => true
  validates :name, :last_name, :language, :email, :presence => true
  validates :user, :email, :uniqueness => {:case_sensitive => false}
  validates :name, :uniqueness =>
    {:case_sensitive => false, :scope => :last_name}
  validates :user, :length => {:in => 5..30}
  validates :name, :last_name, :email, :length => {:maximum => 100},
    :allow_nil => true, :allow_blank => true
  validates :language, :length => {:maximum => 10}, :allow_nil => true,
    :allow_blank => true
  validates :password, :length => {:maximum => 128}, :allow_nil => true,
    :allow_blank => true
  validates :function, :salt, :change_password_hash,
    :length => {:maximum => 255}, :allow_nil => true, :allow_blank => true
  validates :password, :confirmation => true, :unless => :is_encrypted?
  validates_each :manager_id do |record, attr, value|
    if value
      parent = User.find(value)
      is_in_the_same_organization = record.organization_roles.any? do |o_r|
        parent.organization_roles.map(&:organization_id).include?(
          o_r.organization_id
        )
      end

      if record.children.to_a.include?(parent) || !is_in_the_same_organization
        record.errors.add attr, :invalid
      end
    end
  end
  validates_each :organization_roles do |record, attr, value|
    if value.reject(&:marked_for_destruction?).blank?
      record.errors.add attr, :blank unless record.group_admin == true
    end
  end
  validates_each :password do |record, attr, value|
    user = User.find(record.id) if record.id && User.exists?(record.id)

    if user
      digested_password = User.digest(value, user.salt) if value && user
      repeated = false
      password_min_length = record.get_parameter_for_now(
        :security_password_minimum_length).to_i
      password_min_time = record.get_parameter_for_now(
        :security_password_minimum_time).to_i
      password_regex = Regexp.new record.get_parameter_for_now(
        :security_password_constraint)

      record.errors.add attr, :invalid if value && value !~ password_regex

      # Longitud mínima
      if password_min_length != 0 && value && value.length < password_min_length
        record.errors.add attr, :too_short, :count => password_min_length
      end

      # Intervalo mínimo
      if password_min_time != 0 && value != record.password_was &&
          record.password_changed_was > password_min_time.days.ago.to_date &&
          !record.first_login?
        record.errors.add attr, :too_soon, :count => password_min_time
      end

      # Repetición de contraseñas anteriores
      if user && value && user.password != digested_password
        repeated = record.last_passwords.any? do |p|
          digested_password == p.password
        end
      elsif user && value
        repeated = true
      end

      record.errors.add attr, :already_used if repeated
    end
  end
  validates_format_of :email, :with => EMAIL_REGEXP, :allow_nil => true,
    :allow_blank => true

  # Relaciones
  belongs_to :resource
  has_many :polls, :dependent => :destroy
  has_many :old_passwords, :dependent => :destroy
  has_many :login_records, :dependent => :destroy
  has_many :error_records, :dependent => :destroy
  has_many :notifications, :dependent => :destroy
  has_many :detracts, :dependent => :destroy,
    :order => "#{Detract.table_name}.created_at ASC"
  has_many :resource_utilizations, :as => :resource, :dependent => :destroy
  has_many :review_user_assignments, :dependent => :destroy,
    :include => :review, :order => 'assignment_type DESC', :inverse_of => :user
  has_many :reviews, :through => :review_user_assignments, :uniq => true
  has_many :organization_roles, :dependent => :destroy,
    :order => 'organization_id ASC', :after_add => :mark_roles_as_changed,
    :after_remove => :mark_roles_as_changed
  has_many :organizations, :through => :organization_roles, :uniq => true
  has_many :finding_user_assignments
  has_many :related_user_relations, :dependent => :destroy
  has_many :related_users, :through => :related_user_relations
  has_many :findings, :through => :finding_user_assignments,
    :source => :raw_finding, :class_name => 'Finding', :uniq => true
  has_many :weaknesses, :through => :finding_user_assignments,
    :source_type => 'Weakness', :source => :finding, :uniq => true
  has_many :oportunities, :through => :finding_user_assignments,
    :source_type => 'Oportunity', :source => :finding, :uniq => true

  accepts_nested_attributes_for :organization_roles, :allow_destroy => true,
    :reject_if => proc { |attributes|
      attributes['organization_id'].blank? || attributes['role_id'].blank?
    }
  accepts_nested_attributes_for :related_user_relations, :allow_destroy => true,
    :reject_if => proc { |attributes| attributes['related_user_id'].blank? }

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.enable ||= false
    self.send_notification_email = true if self.send_notification_email.nil?
    self.password_changed = Time.now

    if self.send_notification_email
      self.change_password_hash = UUIDTools::UUID.random_create.to_s
    end
  end

  def <=>(other)
    other.kind_of?(User) ? self.id <=> other.id : -1
  end

  def to_s
    self.user
  end

  def to_param
    self.user_changed? ? self.user_was : self.user
  end

  def as_json(options = nil)
    default_options = {
      :only => [:id],
      :methods => [:label, :informal]
    }

    super(default_options.merge(options || {}))
  end

  def is_an_important_change
    unless @__iaic_first_access
      @is_an_important_change = true
      @__iaic_first_access = true
    end

    @is_an_important_change
  end

  def is_an_important_change=(is_an_important_change)
    @__iaic_first_access = true

    @is_an_important_change = is_an_important_change
  end

  def password_was_encrypted
    unless @__pwe_first_access
      @password_was_encrypted = false
      @__pwe_first_access = true
    end

    @password_was_encrypted
  end

  def password_was_encrypted=(password_was_encrypted)
    @__pwe_first_access = true

    @password_was_encrypted = password_was_encrypted
  end

  def set_proper_parent
    self.organization_roles.each { |o_r| o_r.user = self }
  end

  def mark_roles_as_changed(organization_role)
    organization_role.user = self unless organization_role.frozen?

    self.roles_changed = true
  end

  def first_pending_poll
    self.polls.detect { |p|
      p.answered == false && p.organization.id == GlobalModelConfig.current_organization_id
    }
  end

  def roles(organization_id = nil)
    @organization_roles_cache ||= {}

    unless organization_id
      self.organization_roles.reject do |o_r|
        o_r.marked_for_destruction?
      end.map(&:role).sort
    else
      if @organization_roles_cache[organization_id]
        @organization_roles_cache[organization_id]
      else
        filtered_organization_roles = self.organization_roles.select do |o_r|
          o_r.organization_id == organization_id && !o_r.marked_for_destruction?
        end

        @organization_roles_cache[organization_id] =
          filtered_organization_roles.map(&:role).sort
      end
    end
  end

  def cost_per_unit
    self.resource.try(:cost_per_unit)
  end

  def informal_name(from = nil)
    version = self.version_of from

    [version.name.try(:strip), version.last_name.try(:strip)].compact.join(' ')
  end

  def full_name(from = nil)
    version = self.version_of from

    [version.last_name.try(:strip), version.name.try(:strip)].compact.join(', ')
  end

  alias_method :resource_name, :full_name

  def full_name_with_user(from = nil)
    version = self.version_of from

    "#{version.full_name} (#{version.user})".concat(
      version.string_to_append_if_disable.to_s)
  end

  def full_name_with_function(from = nil)
    version = self.version_of from


    "#{version.full_name}#{version.string_to_append_if_function}".concat(
      version.string_to_append_if_disable.to_s)
  end

  alias_method :label, :full_name_with_function

  def full_name_with_resource(from = nil)
    version = self.version_of from

    "#{version.full_name}#{version.string_to_append_if_resource}".concat(
      version.string_to_append_if_disable.to_s)
  end

  def string_to_append_if_disable
    unless self.enable? || self.full_name.blank?
      " - (#{I18n.t('user.disabled')})"
    end
  end

  def string_to_append_if_function
    " (#{self.function})" unless self.function.blank? || self.full_name.blank?
  end

  def string_to_append_if_resource
    unless self.resource.blank? || self.full_name.blank?
      " (#{self.resource.name})"
    end
  end

  def reset_to_important_change
    self.is_an_important_change = true
  end

  def send_welcome_email
    unless self.send_notification_email.blank?
      Notifier.welcome_email(self).deliver
    end
  end

  def send_notification_if_necesary
    unless self.send_notification_email.blank?
      organization = Organization.find GlobalModelConfig.current_organization_id

      self.reset_password!(organization, false)

      Notifier.welcome_email(self).deliver
    end
  end

  def log_password_change
    self.encrypt_password if self.password

    if self.password && self.password_was != self.password
      @last_passwords = nil
      self.old_passwords.create(:password => self.password_was)
    end
  end

  def check_roles_changes
    if self.roles_changed || self.organization_roles.any? { |o_r| o_r.changed? }
      old_user = User.find(self.id)

      if (old_user.auditor? && self.can_act_as_audited?) ||
          (old_user.can_act_as_audited? && self.auditor?)
        unless self.findings.all_for_reallocation.blank?
          self.organization_roles(true)
          self.errors.add :organization_roles, :invalid

          false
        end
      end
    end
  end

  def reset_password!(organization, notify = true)
    self.change_password_hash = UUIDTools::UUID.random_create.to_s
    self.hash_changed = Time.now

    Notifier.restore_password(self, organization).deliver if notify

    self.save!
  end

  def disable!
    if self.has_not_orphan_fingings?
      self.update_attribute :enable, false
    else
      false
    end
  end

  # Método para determinar si el usuario está o no habilitado
  def is_enable?
    self.enable? && GlobalModelConfig.current_organization_id && !self.expired?
  end

  def is_group_admin?
    self.group_admin == true && self.enable == true
  end

  def expired?
    self.last_access.present? && self.last_access <
      self.get_parameter(:security_acount_expire_time).to_i.days.ago
  end

  def password_expired?
    self.password_changed.to_time <
      self.get_parameter(:security_password_expire_time).to_i.days.ago
  end

  def first_login?
    self.last_access.blank? || self.last_access_was.blank?
  end

  def must_change_the_password?
    is_enable? && (password_expired? || first_login?)
  end

  def days_for_password_expiration
    expire_notification = self.get_parameter(:security_expire_notification).to_i

    warning_date = expire_notification.days.ago
    password_changed = self.password_changed.to_time

    if expire_notification != 0 && password_changed < warning_date
      expire_time_in_days = self.get_parameter(
        :security_password_expire_time).to_i

      unless expire_time_in_days == 0
        expire_date = expire_time_in_days.days.ago
        days_to_expire = ((password_changed - expire_date) / 1.days).round
      end
    end

    days_to_expire
  end

  def allow_concurrent_access?
    allow = true

    if self.get_parameter_for_now(:security_allow_concurrent_sessions).to_i == 0
      session_expire = self.get_parameter(:security_session_expire_time).to_i

      allow = !(self.logged_in? &&
          self.last_access > session_expire.minutes.ago)
    end

    allow
  end

  def logged_in!(time = Time.now)
    self.is_an_important_change = false
    self.failed_attempts = 0
    self.logged_in = true
    self.last_access = time unless first_login?

    self.save(:validate => false)
  end

  def logout!
    self.is_an_important_change = false

    self.update_attribute :logged_in, false
  end

  def related_users_and_descendants
    self.related_users + self.related_users.map(&:descendants).flatten.uniq
  end

  def allowed_modules
    allowed_modules = []

    self.roles.each do |role|
      role.allowed_modules.each do |c|
        if role.has_privilege_for?(c) && !allowed_modules.include?(c)
          allowed_modules << c
        end
      end
    end

    allowed_modules
  end

  # Cifra la contraseña con SHA512
  def encrypt_password
    self.salt ||= self.create_new_salt

    unless is_encrypted?
      self.password = User.digest(self.password, self.salt)
      self.password_was_encrypted = true
    end
  end

  def last_passwords
    limit = self.get_parameter(:security_password_count).to_i - 1

    @last_passwords ||= self.old_passwords.order('created_at DESC').limit(
      limit > 0 ? limit : 0)
  end

  def create_new_salt
    Digest::SHA512.hexdigest(self.object_id.to_s + rand.to_s)
  end

  def self.digest(string, salt)
    Digest::SHA512.hexdigest("#{salt}-#{string}")
  end

  def is_encrypted?
    self.password && self.password.length > 120 &&
      self.password =~ /^(\d|[a-f])+$/
  end

  def has_not_orphan_fingings?
    unless self.findings.all_for_reallocation.blank?
      self.errors.add :base, I18n.t('user.will_be_orphan_findings')

      false
    else
      true
    end
  end

  def get_menu
    self.audited? ? 'audited_menu' : 'auditor_menu'
  end

  def get_type
    self.roles(GlobalModelConfig.current_organization_id).max.try(:get_type)
  end

  def privileges(organization)
    privileges = HashWithIndifferentAccess.new

    self.roles(organization.id).each do |role|
      role.privileges.each do |privilege|
        module_name = privilege.module.to_sym
        privileges[module_name] ||= HashWithIndifferentAccess.new

        privileges[module_name][:read] ||= privilege.read?
        privileges[module_name][:modify] ||= privilege.modify?
        privileges[module_name][:erase] ||= privilege.erase?
        privileges[module_name][:approval] ||= privilege.approval?
      end
    end

    privileges
  end

  # Definición dinámica de todos los métodos "tipo?"
  Role::TYPES.each do |type, value|
    define_method("#{type}?") do
      self.roles(GlobalModelConfig.current_organization_id).any? do |role|
        role.role_type == value
      end
    end
  end

  def auditor?
    self.auditor_junior? || self.auditor_senior?
  end

  def can_act_as_audited?
    self.audited? || self.executive_manager?
  end

  def inject_auth_privileges_in_roles
    if restoring_model
      self.roles.each { |r| r.inject_auth_privileges(Hash.new(Hash.new(true))) }
    end
  end

  def release_for_all_pending_findings(options = {})
    options.assert_valid_keys(:with_reviews, :with_findings)

    all_released = true
    items_for_notification = []
    self.reallocation_errors ||= []

    Finding.transaction do
      if options[:with_findings]
        self.findings.all_for_reallocation.each do |f|
          description = "#{f.class.model_name.human} *#{f.review_code.strip}* " +
            "(#{Review.model_name.human} *#{f.review.identification.strip}*)"
          f.avoid_changes_notification = true
          f.users.delete self
          items_for_notification << description

          if f.invalid?
            all_released = false

            self.reallocation_errors << [description, f.errors.full_messages]
          end
        end
      end


      if options[:with_reviews]
        self.review_user_assignments.each do |rua|
          unless rua.review.has_final_review?
            items_for_notification << "#{Review.model_name.human} " +
              rua.review.identification

            unless rua.destroy_without_notification
              all_released = false
              description =
                "#{Review.model_name.human}: *#{rua.review.identification.strip}*"

              self.reallocation_errors << [description,rua.errors.full_messages]
            end
          else
            true
          end
        end
      end

      unless all_released
        self.errors.add :base, I18n.t('user.user_release_failed')

        raise ActiveRecord::Rollback
      end
    end

    if all_released && !items_for_notification.empty?
      title = I18n.t('user.responsibility_release.title')

      Notifier.changes_notification(self, :title => title,
        :content => items_for_notification).deliver
    end

    all_released
  end

  def reassign_to(other, options = {})
    options.assert_valid_keys(:with_reviews, :with_findings)

    unconfirmed_findings = []
    reassigned_reviews = []
    all_reassigned = true
    self.reallocation_errors = []

    unless other == self
      Finding.transaction do
        if options[:with_findings]
          self.findings.all_for_reallocation.each do |f|
            old_fua = f.finding_user_assignments.detect {|fua| fua.user == self}
            f.avoid_changes_notification = true

            unless f.users.include?(other)
              f.finding_user_assignments.create(
                :user => other,
                :process_owner => old_fua.process_owner
              )
            end

            f.finding_user_assignments.delete(old_fua)

            unconfirmed_findings << f if f.unconfirmed?

            if f.invalid?
              all_reassigned = false
              description = "#{f.class.model_name.human} *#{f.review_code.strip}* " +
                "(#{Review.model_name.human} *#{f.review.identification.strip}*)"

              self.reallocation_errors << [description, f.errors.full_messages]
            end
          end
        end

        if options[:with_reviews]
          self.review_user_assignments.each do |rua|
            unless rua.review.has_final_review?
              rua.notify_by_email = false
              findings = rua.review.weaknesses + rua.review.oportunities
              unconfirmed_findings_in_review = findings.select do |f|
                f.unconfirmed? && !unconfirmed_findings.include?(f)
              end

              unconfirmed_findings.concat(unconfirmed_findings_in_review)

              reassigned_reviews << "*#{rua.review.identification}*"

              unless rua.update_attribute :user, other
                all_reassigned = false
                description = "#{Review.model_name.human}: " +
                  "*#{rua.review.identification.strip}*"

                self.reallocation_errors << [description,
                  rua.errors.full_messages]
              end
            else
              true
            end
          end
        end

        if all_reassigned
          reviews = other.findings.all_for_reallocation.map do |f|
            "*#{f.review.identification}*"
          end.uniq.sort

          if (reviews.size + reassigned_reviews.size) > 0
            title = I18n.t('user.responsibility_modification.title')
            body = (reviews.blank? ? '' : I18n.t(
                'user.responsibility_modification.reassigned_to_findings_from_reviews',
                :reviews => reviews.to_sentence, :count => reviews.size))
            body << "\n\n" unless body.blank?
            body << (reassigned_reviews.sort!.blank? ? '' : I18n.t(
              'user.responsibility_modification.reassigned_to_reviews',
              :reviews => reassigned_reviews.to_sentence,
              :count => reassigned_reviews.size))
            content = [
              I18n.t('user.responsibility_modification.old_responsible',
                :responsible => self.full_name_with_function),
              I18n.t('user.responsibility_modification.new_responsible',
                :responsible => other.full_name_with_function)]

            Notifier.changes_notification([other, self], :title => title,
              :body => body, :content => content).deliver
          end

          unless unconfirmed_findings.blank?
            title = I18n.t('user.unconfirmed_findings')
            content = ''
            notification = Notification.create(
              :findings => unconfirmed_findings, :user => other)

            unconfirmed_findings.group_by(&:review).each do |r, findings|
              content << "*#{Review.model_name.human} #{r.identification}*"

              findings.each do |f|
                model = f.class
                content << "\n* #{model.human_attribute_name('review_code')}: "
                content << "_#{f.review_code}_"
                content << "\n** #{model.human_attribute_name('description')}: "
                content << "_#{f.description}_"

                if f.respond_to?(:risk_text)
                  content << "\n** #{model.human_attribute_name('risk')}: "
                  content << "_#{f.risk_text}_"
                end
              end

              content << "\n\n"
            end

            Notifier.changes_notification(other, :title => title,
              :content => content, :notification => notification).deliver
          end
        end

        raise ActiveRecord::Rollback unless all_reassigned
      end

      all_reassigned
    else
      false
    end
  end

  def self.notify_new_findings
    # Sólo si no es sábado o domingo
    unless [0, 6].include?(Date.today.wday)
      emails = []
      findings = User.all_with_findings_for_notification.inject([]) do |f, user|
        emails << Notifier.notify_new_findings(user)

        f | user.findings.for_notification
      end

      Finding.transaction do
        all_changed = findings.all? { |finding| finding.mark_as_unconfirmed! }

        raise ActiveRecord::Rollback unless all_changed

        emails.each { |email| email.deliver }
      end
    end
  end
end
