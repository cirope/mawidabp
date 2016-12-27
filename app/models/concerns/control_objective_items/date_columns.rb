module ControlObjectiveItems::DateColumns
  extend ActiveSupport::Concern

  included do
    if ActiveRecord::ConnectionAdapters.const_defined?(:OracleEnhancedAdapter)
      set_date_columns :audit_date
    end
  end
end
