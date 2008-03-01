class CreateConclusionReviews < ActiveRecord::Migration
  def self.up
    create_table :conclusion_reviews do |t|
      # Discriminator for inheritance
      t.string :type
      t.references :review
      t.date :issue_date
      t.date :close_date
      t.text :applied_procedures
      t.text :conclusion
      t.boolean :approved
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :conclusion_reviews, :review_id
    add_index :conclusion_reviews, :type
  end

  def self.down
    remove_index :conclusion_reviews, :column => :review_id
    remove_index :conclusion_reviews, :column => :type

    drop_table :conclusion_reviews
  end
end