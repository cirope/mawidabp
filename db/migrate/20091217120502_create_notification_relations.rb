class CreateNotificationRelations < ActiveRecord::Migration
  def self.up
    create_table :notification_relations do |t|
      t.references :notification
      t.references :model, :polymorphic => true

      t.timestamps null: false
    end

    add_index :notification_relations, [:model_type, :model_id]
    add_index :notification_relations, :notification_id
  end

  def self.down
    remove_index :notification_relations, :column => [:model_type, :model_id]
    remove_index :notification_relations, :column => :notification_id

    drop_table :notification_relations
  end
end
