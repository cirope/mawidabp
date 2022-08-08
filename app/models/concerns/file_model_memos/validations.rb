module FileModelMemos::Validations
  extend ActiveSupport::Concern

  included do
    validates :file_model_id, uniqueness: { scope: :memo_id }
  end
end
