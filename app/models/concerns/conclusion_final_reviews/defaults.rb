module ConclusionFinalReviews::Defaults
  extend ActiveSupport::Concern

  included do
    attr_accessor :import_from_draft

    after_initialize :set_defaults, if: :new_record?
  end

  def duplicate_annexes_and_images_from_draft
    draft = ConclusionDraftReview.where(review_id: review_id).first

    if draft
      draft.annexes.each do |annex|
        new_annex = annexes.build annex.attributes.dup.merge('id' => nil)

        annex.image_models.each do |image_model|
          new_image       = ImageModel.new
          new_image.image = File.open image_model.image.path

          new_annex.image_models << new_image
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
