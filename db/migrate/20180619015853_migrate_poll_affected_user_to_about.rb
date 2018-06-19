class MigratePollAffectedUserToAbout < ActiveRecord::Migration[5.1]
  def change
    remove_index :polls, :affected_user_id
    rename_column :polls, :affected_user_id, :about_id
    add_column :polls, :about_type, :string

    Poll.where.not(about_id: nil).update_all(about_type: User.name)

    add_index :polls, [:about_id, :about_type]
    add_index :polls, [:about_type, :about_id]
  end
end
