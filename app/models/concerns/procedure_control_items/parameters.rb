module ProcedureControlItems::Parameters
  extend ActiveSupport::Concern

  included do
    APPROACH_TYPES = {
      control: 0,
      sustantive: 1,
      control_sustantive: 2
    }

    FREQUENCY_TYPES = {
      monthly: 0,
      biyearly: 1,
      yearly: 2
    }
  end

  def approach_label
    APPROACH_TYPES.invert[self.aproach]
  end
end
