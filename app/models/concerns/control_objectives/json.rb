module ControlObjectives::JSON
  extend ActiveSupport::Concern

  def as_json options = nil
    default_options = {
      only: [:id],
      methods: [:label, :informal]
    }

    super default_options.merge(options || {})
  end
end
