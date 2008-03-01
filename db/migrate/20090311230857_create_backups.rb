class CreateBackups < ActiveRecord::Migration
  def self.up
    create_table :backups do |t|
      t.integer :backup_type
      t.boolean :work_papers_included
      t.integer :lock_version, :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :backups
  end
end