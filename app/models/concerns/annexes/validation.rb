# frozen_string_literal: true

module Annexes::Validation
  extend ActiveSupport::Concern

  included do
    validates :title, presence: true, length: { maximum: 255 }

    validate :description_or_image_presence
  end

  def description_or_image_presence
    if description.blank? && !images.attached?
      errors.add :description, :blank
      errors.add :image_models, :blank
    end
  end
end
