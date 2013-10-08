module Parameters::Frequency
  extend ActiveSupport::Concern

  included do
    FREQUENCY_TYPES = {
      monthly: 0,
      biyearly: 1,
      yearly: 2
    }
  end

  module ClassMethods
    def frequencies
      FREQUENCY_TYPES
    end

    def frequencies_values
      FREQUENCY_TYPES.values
    end
  end

  def approach_label
    I18n.t "frequency_types.#{FREQUENCY_TYPES.invert[self.frequency]}"
  end
end
