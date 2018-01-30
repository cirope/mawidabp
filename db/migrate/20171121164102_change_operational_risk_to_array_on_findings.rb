class ChangeOperationalRiskToArrayOnFindings < ActiveRecord::Migration[5.1]
  def change
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      change_column :findings, :operational_risk, :text, array: true, default: [],
        using: "(string_to_array(operational_risk, ','))"
    elsif ActiveRecord::Base.connection.adapter_name == 'OracleEnhanced'
      # Don't care about data, Oracle users don't have this feature enabled
      remove_column :findings, :operational_risk
      add_column :findings, :operational_risk, :text, array: true, default: [].to_json
    else
      change_column :findings, :operational_risk, :text, array: true, default: [].to_json
    end
  end
end
