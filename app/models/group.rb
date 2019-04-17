class Group < ApplicationRecord
  include Trimmer
  include Groups::Auditable
  include Groups::Current
  include Groups::Notifications
  include Groups::Validations

  trimmed_fields :name, :admin_email, :admin_hash

  has_many :organizations, -> { order(name: :asc) }, dependent: :destroy
  has_many :users, through: :organizations
  accepts_nested_attributes_for :organizations, allow_destroy: true

  has_many :ldap_configs, through: :organizations

  def initialize attributes = nil
    super attributes

    self.send_notification_email = true if send_notification_email.nil?

    if send_notification_email
      self.admin_hash = SecureRandom.urlsafe_base64
    end
  end
end
