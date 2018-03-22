module Parameters::Priority
  extend ActiveSupport::Concern

  included do
    ::PRIORITY_TYPES = priority_types unless defined? ::PRIORITY_TYPES
  end

  module ClassMethods
    def priorities
      PRIORITY_TYPES
    end

    def priorities_values
      PRIORITY_TYPES.values
    end

    private

      def priority_types
        if HIDE_WEAKNESS_PRIORITY
          { default: 0 }
        else
          { low: 0, medium: 1, high: 2 }
        end
      end
  end
end
