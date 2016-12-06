module Organizations::Images
  extend ActiveSupport::Concern

  included do
    after_destroy :destroy_image_model # TODO: delete when Rails fix gets in stable

    has_one :image_model, as: :imageable, dependent: :destroy
    accepts_nested_attributes_for :image_model, allow_destroy: true, reject_if: :image_blank? 
  end

  private

    def destroy_image_model
      image_model.try :destroy!
    end

    def image_blank? attrs
      ['image', 'image_cache'].all? { |a| attrs[a].blank? }
    end
end
