class AddExtensionToFinding < ActiveRecord::Migration[6.0]
  def change
    add_column :findings, :extension, :boolean, default: false, null: false
  end
end
