# frozen_string_literal: true

module ActiveStorage::HasOneImage
  extend ActiveSupport::Concern

  included do
    has_one_attached :image

    accepts_nested_attributes_for :image_attachment, allow_destroy: true

    after_save :purge_unattacheds

    validate :image_extension
  end

  private

    def purge_unattacheds
      # podemos moverlo a un rake y tambien en vez de purge podemos llamar purge_later
      ActiveStorage::Blob.unattached.each(&:purge)
    end

    def image_extension
      if image.attached? && %w[image/jpg image/jpeg image/gif image/png].exclude?(image.content_type)
        errors.add :image, :extension_whitelist_error
      end
    end
end
