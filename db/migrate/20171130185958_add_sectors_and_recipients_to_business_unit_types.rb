class AddSectorsAndRecipientsToBusinessUnitTypes < ActiveRecord::Migration[5.1]
  def change
    change_table :business_unit_types do |t|
      t.text :sectors
      t.text :recipients
    end
  end
end
