class AddOriginalIdToFindings < ActiveRecord::Migration
  def self.up
    add_column :findings, :repeated_of_id, :integer

    add_index :findings, :repeated_of_id
  end

  def self.down
    remove_index :findings, :column => :repeated_of_id

    remove_column :findings, :repeated_of_id
  end
end