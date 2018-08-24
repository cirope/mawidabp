module Questionnaires::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :organization, :email_subject, :email_text, :email_link,
      presence: true
    validates :name, uniqueness: true, allow_nil: true, allow_blank: true
    validates :name, :email_subject, :email_text, :email_link,
      :email_clarification, pdf_encoding: true
    validates :name, :email_subject, :email_link, length: { maximum: 255 },
      allow_nil: true, allow_blank: true

    before_destroy :check_for_answered_polls, prepend: true
  end

  private

    def check_for_answered_polls
      unless polls.answered(true).count.zero?
        errors.add(:base, :cannot_destroy_with_answered_poll)
        throw :abort
      end
    end
end
