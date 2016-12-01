module Tags::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, :kind, :style, :icon, presence: true, length: { maximum: 255 }
    validates :name, uniqueness: { case_sensitive: false, scope: :group_id }
    validates :icon, inclusion: { in: :available_icons }
    validates :kind, inclusion: {
      in: %w(document finding news plan_item review)
    }
    validates :style, inclusion: {
      in: %w(default primary success info warning danger)
    }
  end
end
