class AddOrganizationalUnitToUsers < ActiveRecord::Migration[6.0]
  def change
    change_table :users do |t|
      t.string :organizational_unit
    end
  end
end
