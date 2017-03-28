class CreateFindings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :findings do |t|
      # Comunes
      t.string :type
      t.string :review_code
      t.text :description
      t.text :answer
      t.text :audit_comments
      t.date :solution_date
      t.date :first_notification_date
      t.date :confirmation_date
      t.date :origination_date
      t.boolean :final
      t.integer :parent_id
      t.integer :state
      t.integer :notification_level, :default => 0
      t.integer :lock_version, :default => 0
      t.references :control_objective_item
      # Weakness
      t.text :audit_recommendations
      t.text :effect
      t.integer :risk
      t.integer :highest_risk
      t.integer :priority
      t.date :follow_up_date

      t.timestamps null: false
    end

    add_index :findings, :control_objective_item_id
    add_index :findings, :parent_id
    add_index :findings, :type
    add_index :findings, :first_notification_date
    add_index :findings, :final
    add_index :findings, :state
    add_index :findings, :created_at
  end

  def self.down
    remove_index :findings, :column => :control_objective_item_id
    remove_index :findings, :column => :parent_id
    remove_index :findings, :column => :type
    remove_index :findings, :column => :first_notification_date
    remove_index :findings, :column => :final
    remove_index :findings, :column => :state
    remove_index :findings, :column => :created_at

    drop_table :findings
  end
end
