class Group < ActiveRecord::Base
  include Trimmer
  include Groups::Auditable
  include Groups::Current
  include Groups::Notifications
  include Groups::Validations

  trimmed_fields :name, :admin_email, :admin_hash

  has_many :organizations, -> { order(name: :asc) }, dependent: :destroy
  accepts_nested_attributes_for :organizations, allow_destroy: true

  def initialize attributes = nil, options = {}
    super attributes, options

    self.send_notification_email = true if send_notification_email.nil?

    if send_notification_email
      self.admin_hash = SecureRandom.urlsafe_base64
    end
  end
end
