class AddOriginalIdToFindings < ActiveRecord::Migration
  def self.up
    add_column :findings, :original_id, :integer

    add_index :findings, :original_id
  end

  def self.down
    remove_index :findings, :column => :original_id

    remove_column :findings, :original_id
  end
end