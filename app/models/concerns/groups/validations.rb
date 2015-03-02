module Groups::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :admin_email, presence: true
    validates :name, :admin_hash, length: { maximum: 255 },
      allow_nil: true, allow_blank: true
    validates :admin_email, length: { maximum: 100 }, allow_nil: true,
      allow_blank: true
    validates :name, :admin_email, uniqueness: { case_sensitive: false  }
    validates :admin_email, format: { with: EMAIL_REGEXP, multiline: true },
      allow_nil: true, allow_blank: true
  end
end
