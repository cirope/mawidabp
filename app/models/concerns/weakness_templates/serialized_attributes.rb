module WeaknessTemplates::SerializedAttributes
  extend ActiveSupport::Concern

  included do
    unless connection.adapter_name == 'PostgreSQL'
      serialize :impact, JSON
      serialize :internal_control_components, JSON
      serialize :operational_risk, JSON
    end
  end
end
