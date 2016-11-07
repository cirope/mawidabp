module Tags::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, :kind, :style, presence: true, length: { maximum: 255 }
    validates :name, uniqueness: { case_sensitive: false, scope: :group_id }
    validates :kind, inclusion: { in: %w(finding plan_item review document) }
    validates :style, inclusion: {
      in: %w(default primary success info warning danger)
    }
  end
end
