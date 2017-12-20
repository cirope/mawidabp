class ChangeOperationalRiskToArrayOnFindings < ActiveRecord::Migration[5.1]
  def change
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      change_column :findings, :operational_risk, :text, array: true, default: [],
        using: "(string_to_array(operational_risk, ','))"
    else
      change_column :findings, :operational_risk, :text, array: true, default: [].to_json
    end
  end
end
