module ResourceUtilizations::Validation
  extend ActiveSupport::Concern

  included do
    validates :units, :resource, :resource_type, presence: true
    validates :units, numericality: { greater_than_or_equal_to: 0 },
      allow_nil: true, allow_blank: true
    validate :check_resource_consumer
  end

  private

    def check_resource_consumer
      if changed? && resource_consumer.respond_to?(:is_frozen?) &&
          resource_consumer.is_frozen?
        errors.add :resource_consumer, :is_frozen
      else
        true
      end
    end
end
