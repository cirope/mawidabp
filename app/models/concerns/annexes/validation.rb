module Annexes::Validation
  extend ActiveSupport::Concern

  included do
    validates :title, presence: true, length: { maximum: 255 }

    validate  :description_or_image_presence
  end

  def description_or_image_presence
    if description.blank? && image_models.empty?
      message = I18n.t('conclusion_draft_review.errors.not_present_description_and_images')
      errors.add(:description, message)
      errors.add(:image_models, message)
    end
  end
end
