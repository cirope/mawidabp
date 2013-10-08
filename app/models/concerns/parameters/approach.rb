module Parameters::Approach
  extend ActiveSupport::Concern

  included do
    APPROACH_TYPES = {
      control: 0,
      sustantive: 1,
      control_sustantive: 2
    }
  end

  module ClassMethods
    def approaches
      APPROACH_TYPES
    end

    def approaches_values
      APPROACH_TYPES.values
    end
  end

  def approach_label
    I18n.t "approach_types.#{RELEVANCE_TYPES.invert[self.aproach]}"
  end
end
