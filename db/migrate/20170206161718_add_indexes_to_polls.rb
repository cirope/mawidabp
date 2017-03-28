class AddIndexesToPolls < ActiveRecord::Migration[4.2]
  def change
    add_index :polls, :user_id
    add_index :polls, [:pollable_id, :pollable_type]

    add_foreign_key :polls, :users, FOREIGN_KEY_OPTIONS.dup
    add_foreign_key :polls, :organizations, FOREIGN_KEY_OPTIONS.dup
    add_foreign_key :polls, :questionnaires, FOREIGN_KEY_OPTIONS.dup
  end
end
