module FindingAnswers::File
  extend ActiveSupport::Concern

  included do
    belongs_to :file_model, dependent: :destroy, optional: true

    accepts_nested_attributes_for :file_model, allow_destroy: true
  end
end
