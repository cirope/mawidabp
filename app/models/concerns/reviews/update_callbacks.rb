module Reviews::UpdateCallbacks
  extend ActiveSupport::Concern

  included do
    before_save :calculate_score
    before_validation :set_proper_parent, :check_if_can_be_modified
  end

  def can_be_modified?
    if has_final_review? && changed?
      msg = I18n.t('review.readonly')

      errors.add(:base, msg) unless errors.full_messages.include?(msg)

      false
    else
      true
    end
  end

  private

    def set_proper_parent
      review_user_assignments.each { |rua| rua.review = self }
    end

    def check_if_can_be_modified
      throw :abort unless can_be_modified?
    end
end
