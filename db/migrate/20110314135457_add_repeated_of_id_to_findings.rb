class AddRepeatedOfIdToFindings < ActiveRecord::Migration
  def self.up
    add_column :findings, :repeated_of_id, :integer

    add_index :findings, :repeated_of_id
    add_foreign_key :findings, :findings, FOREIGN_KEY_OPTIONS.dup.merge(:column => :repeated_of_id)
  end

  def self.down
    remove_index :findings, :column => :repeated_of_id
    remove_foreign_key :findings, :column => :repeated_of_id

    remove_column :findings, :repeated_of_id
  end
end
