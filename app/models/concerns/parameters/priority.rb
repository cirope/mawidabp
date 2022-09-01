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
        if USE_SCOPE_CYCLE
          { none: 0, low: 1, medium: 2, high: 3 }
        elsif SHOW_CONDENSED_PRIORITIES
          { low: 0, high: 2 }
        else
          { low: 0, medium: 1, high: 2 }
        end
      end
  end
end
