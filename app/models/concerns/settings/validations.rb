module Settings::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :value, :organization, presence: true
    validates :name, :value, length: { maximum: 255 }
    validates :name, uniqueness: { case_sensitive: false, scope: :organization }
    validates :value,
      numericality: { only_integer: true, greater_than_or_equal_to: 0 },
      if: :is_numericality?
  end

  private

    def is_numericality?
      DEFAULT_SETTINGS[name][:validates] == 'numericality' if DEFAULT_SETTINGS[name]
    end
end
