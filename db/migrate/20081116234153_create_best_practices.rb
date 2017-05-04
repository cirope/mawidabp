class CreateBestPractices < ActiveRecord::Migration[4.2]
  def self.up
    create_table :best_practices do |t|
      t.string :name
      t.text :description
      t.references :organization
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :best_practices, :organization_id
    add_index :best_practices, :created_at
  end

  def self.down
    remove_index :best_practices, :column => :organization_id
    remove_index :best_practices, :column => :created_at

    drop_table :best_practices
  end
end
