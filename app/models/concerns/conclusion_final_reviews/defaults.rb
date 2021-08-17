module ConclusionFinalReviews::Defaults
  extend ActiveSupport::Concern

  included do
    attr_accessor :import_from_draft

    after_initialize :set_defaults, if: :new_record?
  end

  def assign_duplicate_images_from_draft ids_images_duplicates
    draft = ConclusionDraftReview.where(review_id: review_id).first

    if draft
      ids_images_duplicates.reverse_each do |id_image_duplicate|
        aux_image = ImageModel.find id_image_duplicate
        new_image = ImageModel.new
        new_image.image = File.open aux_image.image.file.file

        aux_annex = aux_image.imageable
        annexes.each do |annex_duplicate|
          if aux_annex.title == annex_duplicate.title && aux_annex.description == annex_duplicate.description
            annex_duplicate.image_models << new_image
            new_image.imageable = nil
          end
        end
      end
    end
  end

  private

    def set_defaults
      if import_from_draft && self.review
        draft = ConclusionDraftReview.where(review_id: self.review_id).first

        self.attributes = draft.attributes if draft
      end
    end
end
