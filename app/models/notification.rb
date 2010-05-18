class Notification < ActiveRecord::Base
  
  # Constantes
  STATUSES = {
    :unconfirmed => 0,
    :confirmed => 1,
    :rejected => 2
  }

  # Named scopes
  named_scope :not_confirmed, :conditions =>
    { :status => STATUSES[:unconfirmed] }
  named_scope :confirmed_or_stale, :conditions => [
    [
      'status = :status_confirmed',
      [
        'status = :status_unconfirmed', 'created_at <= :stale_date'
      ].join(' AND ')
    ].join(' OR '),
    {
      :status_confirmed => STATUSES[:confirmed],
      :status_unconfirmed => STATUSES[:unconfirmed],
      :stale_date => NOTIFICATIONS_STALE_DAYS.days.ago_in_business
    }
  ]
  named_scope :rejected_or_new, :conditions => [
    [
      'status = :status_rejected',
      [
        'status = :status_unconfirmed', 'created_at > :stale_date'
      ].join(' AND ')
    ].join(' OR '),
    {
      :status_rejected => STATUSES[:confirmed],
      :status_unconfirmed => STATUSES[:unconfirmed],
      :stale_date => NOTIFICATIONS_STALE_DAYS.days.ago_in_business
    }
  ]

  # Restricciones
  validates_presence_of :confirmation_hash, :user_id
  validates_numericality_of :user_who_confirm_id, :user_id, :status,
    :only_integer => true, :allow_nil => true, :allow_blank => true
  validates_length_of :confirmation_hash, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_datetime :confirmation_date, :allow_nil => true,
    :allow_blank => true

  # Relaciones
  belongs_to :user
  belongs_to :user_who_confirm, :class_name => 'User'
  has_many :notification_relations
  has_many :findings, :through => :notification_relations, :source => :model,
    :source_type => 'Finding'
  has_many :conclusion_reviews, :through => :notification_relations,
    :source => :model, :source_type => 'ConclusionReview'

  def initialize(attributes = nil)
    super(attributes)

    self.status ||= STATUSES[:unconfirmed]
    self.confirmation_hash ||= UUIDTools::UUID.random_create.to_s
  end

  def to_param
    self.confirmation_hash
  end

  def notify!(confirmed = true)
    Notification.transaction do
      begin
        self.update_attributes(
          :status => confirmed ? STATUSES[:confirmed] : STATUSES[:rejected],
          :user_who_confirm => self.user,
          :confirmation_date => Time.now
        )

        self.findings.each do |finding|
          finding.confirmed! if self.user.audited?

          finding.notifications.each do |notification|
            unless notification.notified? || notification.id == self.id ||
                (self.user.audited? ^ notification.user.audited?)
              notification.update_attributes!(
                :status => confirmed ?
                  STATUSES[:confirmed] : STATUSES[:rejected],
                :user_who_confirm => self.user
              )
            end
          end
        end
        
        true
      rescue ActiveRecord::RecordInvalid
        raise ActiveRecord::Rollback
      end
    end
  end

  STATUSES.each do |status_type, status_value|
    define_method("#{status_type}?") { self.status == status_value }
  end

  def notified?
    !self.unconfirmed?
  end

  def status_text
    I18n.t("notification.status_#{STATUSES.invert[self.status]}")
  end

  def stale?
    self.unconfirmed? &&
      self.created_at <= NOTIFICATIONS_STALE_DAYS.days.ago_in_business
  end
end