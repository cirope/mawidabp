module Activities::Validation
  extend ActiveSupport::Concern

  included do
  validates :name, presence: true,
                   length: { maximum: 255 },
                   uniqueness: { case_sensitive: false, scope: :activity_group }
  end
end
