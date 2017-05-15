class AddAffectedUserIdToPolls < ActiveRecord::Migration[4.2]
  def change
    add_reference :polls, :affected_user, index: true

    add_foreign_key :polls, :users, FOREIGN_KEY_OPTIONS.dup.merge(column: :affected_user_id)
  end
end
