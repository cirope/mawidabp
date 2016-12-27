module PlanItems::DateColumns
  extend ActiveSupport::Concern

  included do
    if ActiveRecord::ConnectionAdapters.const_defined?(:OracleEnhancedAdapter)
      set_date_columns :start, :end
    end
  end
end
