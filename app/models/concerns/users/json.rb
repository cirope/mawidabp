module Users::JSON
  extend ActiveSupport::Concern

  def as_json options = nil
    default_options = {
      only: [:id],
      methods: [:label, :informal, :cost_per_unit, :can_act_as_audited?]
    }

    super default_options.merge(options || {})
  end
end
