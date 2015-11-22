module Findings::CreateValidation
  extend ActiveSupport::Concern

  included do
    before_create :can_be_created?
  end

  def can_be_created?
    if is_in_a_final_review? && (changed? || marked_for_destruction?)
      msg = I18n.t('finding.readonly')

      errors.add :base, msg unless errors.full_messages.include? msg

      false
    end
  end
end
