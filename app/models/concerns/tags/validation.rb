module Tags::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, :kind, :style, :icon, presence: true, length: { maximum: 255 }
    validates :name, uniqueness: { case_sensitive: false, scope: :group_id }
    validates :icon, inclusion: { in: :available_icons }
    validates :kind, inclusion: { in: Tag::KINDS }
    validates :style, inclusion: {
      in: %w(default primary success info warning danger)
    }
    validate :shared_reversion
  end

  private

    def shared_reversion
      errors.add :shared, :invalid if shared_was && !shared
    end
end
