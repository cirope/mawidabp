# frozen_string_literal: true

module Annexes::ImageModels
  extend ActiveSupport::Concern

  included do
    has_many :image_models, as: :imageable, dependent: :destroy

    accepts_nested_attributes_for :image_models, allow_destroy: true, reject_if: :all_blank
  end

  def organization_id
    conclusion_review.review.organization_id
  end
end
