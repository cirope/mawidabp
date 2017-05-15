class CreatePlans < ActiveRecord::Migration[4.2]
  def self.up
    create_table :plans do |t|
      t.references :period
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :plans, :period_id
  end

  def self.down
    remove_index :plans, :column => :period_id

    drop_table :plans
  end
end
