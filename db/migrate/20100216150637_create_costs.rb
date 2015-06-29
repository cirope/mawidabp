class CreateCosts < ActiveRecord::Migration
  def self.up
    create_table :costs do |t|
      t.text :description
      t.string :cost_type
      t.decimal :cost, :precision => 15, :scale => 2
      t.references :item, :polymorphic => true
      t.references :user

      t.timestamps null: false
    end

    add_index :costs, [:item_type, :item_id]
    add_index :costs, :user_id
    add_index :costs, :cost_type
  end

  def self.down
    remove_index :costs, :column => [:item_type, :item_id]
    remove_index :costs, :column => :user_id
    remove_index :costs, :column => :cost_type

    drop_table :costs
  end
end
