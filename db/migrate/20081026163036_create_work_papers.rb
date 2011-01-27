class CreateWorkPapers < ActiveRecord::Migration
  def self.up
    create_table :work_papers do |t|
      t.string :name
      t.string :code
      t.integer :number_of_pages
      t.text :description
      t.references :owner, :polymorphic => true
      t.references :file_model
      t.references :organization
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :work_papers, [:owner_type, :owner_id]
    add_index :work_papers, :file_model_id
    add_index :work_papers, :organization_id
  end

  def self.down
    remove_index :work_papers, :column => [:owner_type, :owner_id]
    remove_index :work_papers, :column => :file_model_id
    remove_index :work_papers, :column => :organization_id

    drop_table :work_papers
  end
end