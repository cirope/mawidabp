module Organizations::Images
  extend ActiveSupport::Concern

  included do
    after_destroy :destroy_image_models # TODO: delete when Rails fix gets in stable

    has_one :image_model, -> { order :created_at }, as: :imageable, dependent: :destroy
    accepts_nested_attributes_for :image_model, allow_destroy: true, reject_if: :image_blank?

    has_one :co_brand_image_model, ->(o) { where.not id: o.image_model&.id }, as: :imageable, dependent: :destroy, class_name: 'ImageModel'
    accepts_nested_attributes_for :co_brand_image_model, allow_destroy: true, reject_if: :image_blank?
  end

  private

    def destroy_image_models
      image_model&.destroy!
      co_brand_image_model&.destroy!
    end

    def image_blank? attrs
      ['image', 'image_cache'].all? { |a| attrs[a].blank? }
    end
end
