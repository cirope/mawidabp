module Reviews::FileModelReviews
  extend ActiveSupport::Concern

  included do
    has_many :file_model_reviews
    has_many :file_models, through: :file_model_reviews

    accepts_nested_attributes_for :file_model_reviews, :allow_destroy => true
  end
end
