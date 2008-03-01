class CreateBestPractices < ActiveRecord::Migration
  def self.up
    create_table :best_practices do |t|
      t.string :name
      t.text :description
      t.references :organization
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :best_practices, :organization_id
  end

  def self.down
    remove_index :best_practices, :column => :organization_id

    drop_table :best_practices
  end
end