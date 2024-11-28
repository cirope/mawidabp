class AddStatusToPlans < ActiveRecord::Migration[6.1]
  def change
    add_column :plans, :status, :string, null: false, default: 'draft'
    add_index :plans, :status
  end
end
