module FileModelReviews::Validations
  extend ActiveSupport::Concern

  included do
    validates :file_model_id, :review_id, presence: true
    validates :file_model_id, uniqueness: { scope: :review_id }
  end
end
