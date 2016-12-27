module Users::DateColumns
  extend ActiveSupport::Concern

  included do
    if ActiveRecord::ConnectionAdapters.const_defined?(:OracleEnhancedAdapter)
      set_date_columns :password_changed
    end
  end
end
