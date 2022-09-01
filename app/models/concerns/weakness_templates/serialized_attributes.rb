module WeaknessTemplates::SerializedAttributes
  extend ActiveSupport::Concern

  included do
    unless POSTGRESQL_ADAPTER
      serialize :impact, JSON
      serialize :internal_control_components, JSON
      serialize :operational_risk, JSON
    end
  end
end
