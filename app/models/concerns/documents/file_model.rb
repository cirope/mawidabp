module Documents::FileModel
  extend ActiveSupport::Concern

  included do
    after_initialize :set_organization_id_on_file_model

    belongs_to :file_model, dependent: :destroy, optional: true
    accepts_nested_attributes_for :file_model, allow_destroy: true, reject_if: :all_blank
  end

  private

    def set_organization_id_on_file_model
      file_model.organization_id = organization_id if file_model
    end
end
