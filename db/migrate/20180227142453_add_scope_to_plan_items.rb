class AddScopeToPlanItems < ActiveRecord::Migration[5.1]
  def change
    add_column :plan_items, :scope, :string
  end
end
