class Notification < ActiveRecord::Base
  
  # Constantes
  STATUS = {
    :unconfirmed => 0,
    :confirmed => 1,
    :rejected => 2
  }

  # Named scopes
  scope :not_confirmed, where(:status => STATUS[:unconfirmed])
  scope :confirmed_or_stale, lambda {
    where(
      [
        'status = :status_confirmed',
        [
          'status = :status_unconfirmed',
          'created_at <= :stale_date'
        ].join(' AND ')
      ].join(' OR '),
      {
        :status_confirmed => STATUS[:confirmed],
        :status_unconfirmed => STATUS[:unconfirmed],
        :stale_date => NOTIFICATIONS_STALE_DAYS.days.ago_in_business
      }
    )
  }
  scope :rejected_or_new, lambda {
    where(
      [
        'status = :status_rejected',
        [
          'status = :status_unconfirmed', 'created_at > :stale_date'
        ].join(' AND ')
      ].join(' OR '),
      {
        :status_rejected => STATUS[:confirmed],
        :status_unconfirmed => STATUS[:unconfirmed],
        :stale_date => NOTIFICATIONS_STALE_DAYS.days.ago_in_business
      }
    )
  }

  # Restricciones
  validates :confirmation_hash, :user_id, :presence => true
  validates :user_who_confirm_id, :user_id, :status,
    :numericality => {:only_integer => true}, :allow_nil => true,
    :allow_blank => true
  validates :confirmation_hash, :length => {:maximum => 255},
    :allow_nil => true, :allow_blank => true
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

    self.status ||= STATUS[:unconfirmed]
    self.confirmation_hash ||= UUIDTools::UUID.random_create.to_s
  end

  def to_param
    self.confirmation_hash
  end

  def notify!(confirmed = true)
    Notification.transaction do
      begin
        self.update_attributes(
          :status => confirmed ? STATUS[:confirmed] : STATUS[:rejected],
          :user_who_confirm => self.user,
          :confirmation_date => Time.now
        )

        self.findings.each do |finding|
          finding.confirmed! if self.user.can_act_as_audited?

          finding.notifications.each do |notification|
            unless notification.notified? || notification.id == self.id ||
                (self.user.can_act_as_audited? ^ notification.user.can_act_as_audited?)
              notification.update_attributes!(
                :status => confirmed ?
                  STATUS[:confirmed] : STATUS[:rejected],
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

  STATUS.each do |status_type, status_value|
    define_method("#{status_type}?") { self.status == status_value }
  end

  def notified?
    !self.unconfirmed?
  end

  def status_text
    I18n.t("notification.status_#{STATUS.invert[self.status]}")
  end

  def stale?
    self.unconfirmed? &&
      self.created_at <= NOTIFICATIONS_STALE_DAYS.days.ago_in_business
  end
end