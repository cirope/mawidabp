# frozen_string_literal: true

module ActiveStorage::HasOneFile
  extend ActiveSupport::Concern

  included do
    # attr_accessor :cache_file_blob_id

    # has_one_attached :file_cache

    has_one_attached :file

    accepts_nested_attributes_for :file_attachment, allow_destroy: true

    # lo vamos a tener que mover a un rake que se ejecute en alguna hora de inactividad
    # after_save :purge_unattacheds
  end

  private

    def purge_unattacheds
      # Podemos moverlo a un rake y tambien en vez de purge podemos llamar purge_later
      ActiveStorage::Blob.unattached.each(&:purge)
    end
end
