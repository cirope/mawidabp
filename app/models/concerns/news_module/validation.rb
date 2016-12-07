module NewsModule::Validation
  extend ActiveSupport::Concern

  included do
    validates :title, presence: true, length: { maximum: 255 }
    validates :description, :body, :published_at, :organization, :group,
      presence: true
    validates :published_at, timeliness: { type: :date }, allow_blank: true
  end
end
