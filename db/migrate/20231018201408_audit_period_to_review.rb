class AuditPeriodToReview < ActiveRecord::Migration[6.1]
  def change
    add_column :reviews, :audit_period, :string
  end
end
