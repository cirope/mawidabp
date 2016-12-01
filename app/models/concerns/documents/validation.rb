module Documents::Validation
  extend ActiveSupport::Concern

  included do
    validates :organization, :group, presence: true
    validates :name, presence: true, length: { maximum: 255 }
    validate :has_at_least_one_tag
  end

  private

    def has_at_least_one_tag
      unless taggings.reject(&:marked_for_destruction?).any?
        errors.add :tags, :empty
      end
    end
end
