module Polls::Validations
  extend ActiveSupport::Concern

  included do
    validates :organization_id, :questionnaire, presence: true
    validates :comments, length: { maximum: 255 }, allow_nil: true,
      allow_blank: true
    validates :customer_email, format: { with: EMAIL_REGEXP , multiline: true },
      allow_nil: true, allow_blank: true
    validate :user_id_xor_customer_email
  end

  private

    def user_id_xor_customer_email
      unless user_id.present? ^ customer_email.present?
        errors.add(:base, :invalid)
      end
    end
end
