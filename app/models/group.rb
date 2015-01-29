class Group < ActiveRecord::Base
  include Trimmer

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
  has_many :organizations, -> { order(name: :asc) }, dependent: :destroy

  accepts_nested_attributes_for :organizations, allow_destroy: true

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.send_notification_email = true if send_notification_email.nil?

    if send_notification_email
      self.admin_hash = SecureRandom.urlsafe_base64
    end
  end

  def send_notification_if_necesary
    if send_notification_email.present?
      unless admin_hash
        self.send_notification_email = false

        self.update_attribute :admin_hash, SecureRandom.urlsafe_base64

        self.send_notification_email = true
      end

      NotifierMailer.delay.group_welcome_email(self)
    end
  end
end
