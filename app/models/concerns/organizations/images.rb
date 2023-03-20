module Organizations::Images
  extend ActiveSupport::Concern

  included do
    before_destroy :destroy_image_models # TODO: delete when Rails fix gets in stable

    has_one :image_model, -> { order :created_at }, as: :imageable, dependent: :destroy
    accepts_nested_attributes_for :image_model, allow_destroy: true, reject_if: :image_blank?

    has_one :co_brand_image_model, ->(o) { where.not id: o.image_model&.id }, as: :imageable, dependent: :destroy, class_name: 'ImageModel'
    accepts_nested_attributes_for :co_brand_image_model, allow_destroy: true, reject_if: :image_blank?

    # images with activestorage
    has_one_attached :image

    has_one_attached :co_brand_image

    accepts_nested_attributes_for :image_attachment, allow_destroy: true

    accepts_nested_attributes_for :co_brand_image_attachment, allow_destroy: true

    after_save :purge_unattacheds
  end

  # thumb

  def thumb_image
    image.variant(resize_to_fit: [300, 75], format: :png)
  end

  def thumb_image_geometry
    image_geometry thumb_image
  end

  def thumb_co_brand_image
    co_brand_image.variant(resize_to_fit: [300, 75], format: :png)
  end

  def thumb_co_brand_image_geometry
    image_geometry co_brand_image
  end

  # pdf_thumb

  def pdf_thumb_image
    image.variant(resize_to_fit: [200, 40], format: :png)
  end

  def pdf_thumb_image_geometry
    image_geometry pdf_thumb_image
  end

  def pdf_thumb_co_brand_image
    co_brand_image.variant(resize_to_fit: [200, 40], format: :png)
  end

  def pdf_thumb_co_brand_image_geometry
    image_geometry pdf_thumb_co_brand_image
  end

  private

    def image_geometry image
      if image.present?
        dimensions = {}
        path       = ActiveStorage::Blob.service.path_for image.processed.key

        MiniMagick::Image.open(path)[:dimensions].tap do |dimension|
          dimensions.merge! width: dimension.first, height: dimension.last
        end

        dimensions
      end
    end

    def purge_unattacheds
      # Podemos moverlo a un rake y tambien en vez de purge podemos llamar purge_later
      ActiveStorage::Blob.unattached.each(&:purge)
    end

    def get_version_path version = nil
      version ? image.send(version) : image
    end

    def destroy_image_models
      image_model&.destroy!
      co_brand_image_model&.destroy!
    end

    def image_blank? attrs
      ['image', 'image_cache'].all? { |a| attrs[a].blank? }
    end
end
