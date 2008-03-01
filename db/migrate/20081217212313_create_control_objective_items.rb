class CreateControlObjectiveItems < ActiveRecord::Migration
  def self.up
    create_table :control_objective_items do |t|
      t.text :control_objective_text
      t.text :effects
      t.integer :relevance
      t.text :identified_controls
      t.integer :pre_audit_qualification
      t.text :pre_audit_tests
      t.integer :post_audit_qualification
      t.text :post_audit_tests
      t.date :audit_date
      t.text :auditor_comment
      t.boolean :finished
      t.references :control_objective
      t.references :review
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :control_objective_items, :control_objective_id
    add_index :control_objective_items, :review_id
  end

  def self.down
    remove_index :control_objective_items, :column => :control_objective_id
    remove_index :control_objective_items, :column => :review_id

    drop_table :control_objective_items
  end
end