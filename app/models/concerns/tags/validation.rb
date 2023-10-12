module Tags::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, :kind, :style, :icon, presence: true, length: { maximum: 255 }
    validates :name, uniqueness: { case_sensitive: false, scope: :organization_id }
    validates :name, uniqueness: { case_sensitive: false, scope: :group_id }, if: :shared
    validates :icon, inclusion: { in: :available_icons }
    validates :kind, inclusion: { in: Tag::KINDS }
    validates :style, inclusion: {
      in: %w(secondary primary success info warning danger)
    }
    validate :tag_uniqueness
    validate :shared_reversion
  end

  private

    def tag_uniqueness
        tags = Tag.by_name(name).
          where.not(id: id).
          where(shared: true).any?

        errors.add :name, :taken if tags
    end

    def shared_reversion
      errors.add :shared, :invalid if shared_was && !shared
    end
end
