module Parameters::Priority
  extend ActiveSupport::Concern

  included do
    PRIORITY_TYPES = { low: 0, medium: 1, high: 2 }
  end

  module ClassMethods
    def priorities
      PRIORITY_TYPES
    end

    def priorities_values
      PRIORITY_TYPES.values
    end
  end
end
