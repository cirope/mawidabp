class Group < ActiveRecord::Base
  include Trimmer
  include Associations::DestroyPaperTrail

  trimmed_fields :name, :admin_email, :admin_hash

  has_paper_trail

  # Atributos no persistentes
  attr_accessor :send_notification_email

  # Callbacks
  after_save :send_notification_if_necesary

  # Restricciones
  validates :name, :admin_email, presence: true
  validates :name, :admin_hash, length: { maximum: 255 },
    allow_nil: true, allow_blank: true
  validates :admin_email, length: { maximum: 100 }, allow_nil: true,
    allow_blank: true
  validates :name, :admin_email, uniqueness: { case_sensitive: false  }
  validates :admin_email, format: { with: EMAIL_REGEXP, multiline: true },
    allow_nil: true, allow_blank: true

  # Relaciones
  has_many :organizations, -> { order('name ASC') }, dependent: :destroy

  accepts_nested_attributes_for :organizations, allow_destroy: true

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.send_notification_email = true if send_notification_email.nil?

    if send_notification_email
      self.admin_hash = UUIDTools::UUID.random_create.to_s
    end
  end

  def send_notification_if_necesary
    if send_notification_email.present?
      unless admin_hash
        self.send_notification_email = false

        self.update_attribute :admin_hash, UUIDTools::UUID.random_create.to_s

        self.send_notification_email = true
      end

      Notifier.group_welcome_email(self).deliver
    end
  end
end
