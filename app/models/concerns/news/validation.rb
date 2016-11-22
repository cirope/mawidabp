module News::Validation
  extend ActiveSupport::Concern

  included do
    validates :title, presence: true, length: { maximum: 255 }
    validates :body, :organization, :group, presence: true
  end
end
