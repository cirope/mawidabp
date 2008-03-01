class CreatePlans < ActiveRecord::Migration
  def self.up
    create_table :plans do |t|
      t.references :period
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :plans, :period_id
  end

  def self.down
    remove_index :plans, :column => :period_id

    drop_table :plans
  end
end