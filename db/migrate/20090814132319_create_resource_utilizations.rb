class CreateResourceUtilizations < ActiveRecord::Migration[4.2]
  def self.up
    create_table :resource_utilizations do |t|
      t.decimal :units, :precision => 15, :scale => 2
      t.decimal :cost_per_unit, :precision => 15, :scale => 2
      t.references :resource_consumer, :polymorphic => true
      t.references :resource, :polymorphic => true

      t.timestamps null: false
    end

    add_index :resource_utilizations, [:resource_consumer_id,
      :resource_consumer_type],
      :name => 'ru_consumer_consumer_type_idx'
    add_index :resource_utilizations, [:resource_id, :resource_type],
      :name => 'ru_resource_resource_type_idx'
  end

  def self.down
    remove_index :resource_utilizations,
      :name => 'resource_utilizations_consumer_consumer_type_idx'
    remove_index :resource_utilizations,
      :name => 'resource_utilizations_resource_resource_type_idx'

    drop_table :resource_utilizations
  end
end
