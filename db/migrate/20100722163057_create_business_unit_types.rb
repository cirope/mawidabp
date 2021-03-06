class CreateBusinessUnitTypes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :business_unit_types do |t|
      t.string :name
      t.boolean :external, :default => false, :null => false
      t.string :business_unit_label
      t.string :project_label
      t.references :organization
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :business_unit_types, :name
    add_index :business_unit_types, :external
    add_index :business_unit_types, :organization_id
  end

  def self.down
    remove_index :business_unit_types, :column => :name
    remove_index :business_unit_types, :column => :external
    remove_index :business_unit_types, :column => :organization_id

    drop_table :business_unit_types
  end
end
