class CreateBusinessUnits < ActiveRecord::Migration
  def self.up
    create_table :business_units do |t|
      t.string :name
      t.references :business_unit_type
      
      t.timestamps
    end

    add_index :business_units, :name
    add_index :business_units, :business_unit_type_id
  end

  def self.down
    remove_index :business_units, :column => :name
    remove_index :business_units, :column => :business_unit_type_id

    drop_table :business_units
  end
end