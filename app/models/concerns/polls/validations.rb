module Polls::Validations
  extend ActiveSupport::Concern

  included do
    validates :organization_id, :questionnaire, :user, presence: true
    validates :comments, length: { maximum: 255 }, allow_nil: true,
      allow_blank: true
    validates :about_type, inclusion: { in: [User.name, BusinessUnit.name] },
      allow_nil: true, allow_blank: true
    validates :about_type, presence: true, if: :about_id
  end
end
