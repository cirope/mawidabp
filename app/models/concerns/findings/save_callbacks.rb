module Findings::SaveCallbacks
  extend ActiveSupport::Concern

  included do
    before_save :restore_attributes_to_default_value
  end

  private

    def restore_attributes_to_default_value
      is_oracle = self.class.connection.adapter_name == 'OracleEnhanced'

      if !SHOW_WEAKNESS_EXTRA_ATTRIBUTES && is_oracle
        self.impact = '[]'
        self.internal_control_components = '[]'
      end
    end
end
