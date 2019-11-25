module Users::BaseValidations
  extend ActiveSupport::Concern

  included do
    validates :name, :last_name, :email, presence: true, length: { maximum: 100 },
      pdf_encoding: true
    validates :user, length: { in: 3..30 }, pdf_encoding: true
    validates :email, format: { with: EMAIL_REGEXP }, allow_nil: true, allow_blank: true
  end
end
