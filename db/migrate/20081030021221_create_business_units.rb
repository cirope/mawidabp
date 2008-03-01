class CreateBusinessUnits < ActiveRecord::Migration
  def self.up
    create_table :business_units do |t|
      t.string :name
      t.integer :business_unit_type
      t.references :organization
      
      t.timestamps
    end

    add_index :business_units, :organization_id
  end

  def self.down
    remove_index :business_units, :column => :organization_id

    drop_table :business_units
  end
end