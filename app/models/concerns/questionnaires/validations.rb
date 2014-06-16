module Questionnaires::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :organization, :email_subject, :email_text, :email_link,
      presence: true
    validates :name, uniqueness: true, allow_nil: true, allow_blank: true
    validates :name, :email_subject, :email_text, :email_link,
      :email_clarification, length: { maximum: 255 },
      allow_nil: true, allow_blank: true
  end
end
