module Findings::SerializedAttributes
  extend ActiveSupport::Concern

  included do
    if SHOW_WEAKNESS_EXTRA_ATTRIBUTES && connection.adapter_name != 'PostgreSQL'
      serialize :impact, JSON
      serialize :internal_control_components, JSON
    end
  end
end
