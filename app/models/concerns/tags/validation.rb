module Tags::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, :kind, :style, :icon, presence: true, length: { maximum: 255 }
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
      is_duplicated = Tag.by_name(name).any? do |t|
        if t.shared == true
          true
        elsif new_record? && (t.organization == organization || shared == true)
          true
        elsif persisted? && (t.organization == organization || shared == true && t.organization != organization)
          true
        else
          false
        end
      end

      errors.add :name, :taken if is_duplicated
    end

    def shared_reversion
      errors.add :shared, :invalid if shared_was && !shared
    end
end
