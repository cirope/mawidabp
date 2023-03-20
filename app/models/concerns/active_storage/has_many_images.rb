# frozen_string_literal: true

module ActiveStorage::HasManyImages
  extend ActiveSupport::Concern

  included do
    attr_accessor :blobs_to_purge

    has_many_attached :images

    accepts_nested_attributes_for :images_attachments, allow_destroy: true

    before_save :collect_blobs_to_purge

    after_save :purge_unattacheds

    validate :images_extension
  end

  private

    def collect_blobs_to_purge
      self.blobs_to_purge = images_attachments.select(&:marked_for_destruction?).map(&:blob_id)
    end

    def purge_unattacheds
      # Esto lo hacemos para cuando envio un archivo nuevo y elimino otro a la vez para que 
      # luego de guardar elimine los que habiamos seleccionado para eliminar, sino no se
      # elimina el archivo seleccionado para eliminar
      images_attachments.where(blob_id: blobs_to_purge).each(&:purge)

      # Podemos moverlo a un rake y tambien en vez de purge podemos llamar purge_later
      ActiveStorage::Blob.unattached.each(&:purge)
    end

    def images_extension
      # Voy a validar contra los blobs sino me arroja excepcion de frozen atttributtes
      if images.blobs.any? { |blob| %w[image/jpg image/jpeg image/gif image/png].exclude?(blob.content_type) }
        errors.add :images, :extension_whitelist_error
      end
    end
end
