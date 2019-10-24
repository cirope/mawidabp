module Weaknesses::Image
  extend ActiveSupport::Concern

  included do
    before_destroy :destroy_image_models # TODO: delete when Rails fix gets in stable

    has_one :image_model, as: :imageable, dependent: :destroy
    accepts_nested_attributes_for :image_model, allow_destroy: true, reject_if: :image_blank?
  end

  private

    def destroy_image_models
      image_model&.destroy!
    end

    def image_blank? attrs
      ['image', 'image_cache'].all? { |a| attrs[a].blank? }
    end
end
