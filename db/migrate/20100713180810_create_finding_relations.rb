class CreateFindingRelations < ActiveRecord::Migration[4.2]
  def self.up
    create_table :finding_relations do |t|
      t.string :description, :null => false
      t.references :finding
      t.references :related_finding

      t.timestamps null: false
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
