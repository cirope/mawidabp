class CreateFindingRelations < ActiveRecord::Migration
  def self.up
    create_table :finding_relations do |t|
      t.integer :finding_relation_type
      t.references :finding
      t.references :related_finding

      t.timestamps
    end

    add_index :finding_relations, :finding_id
    add_index :finding_relations, :related_finding_id
  end

  def self.down
    remove_index :finding_relations, :column => :finding_id
    remove_index :finding_relations, :column => :related_finding_id

    drop_table :finding_relations
  end
end