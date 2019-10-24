class MigratePollAffectedUserToAbout < ActiveRecord::Migration[5.1]
  def change
    remove_index :polls, :affected_user_id

    if ActiveRecord::Base.connection.adapter_name == 'SQLite'
      remove_foreign_key :polls, :users, column: :affected_user_id
    else
      remove_foreign_key :polls, column: :affected_user_id
    end

    rename_column :polls, :affected_user_id, :about_id
    add_column :polls, :about_type, :string

    Poll.where.not(about_id: nil).update_all(about_type: User.name)

    add_index :polls, [:about_type, :about_id]
    add_index :polls, :about_id
    add_index :polls, :about_type
  end
end
