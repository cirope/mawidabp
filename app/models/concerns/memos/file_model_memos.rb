module Memos::FileModelMemos
  extend ActiveSupport::Concern

  included do
    has_many :file_model_memos
    has_many :file_models, through: :file_model_memos

    accepts_nested_attributes_for :file_model_memos, allow_destroy: true
  end
end
