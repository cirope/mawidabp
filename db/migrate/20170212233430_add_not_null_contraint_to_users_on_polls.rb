class AddNotNullContraintToUsersOnPolls < ActiveRecord::Migration[4.2]
  def change
    remove_polls_without_users

    change_column_null :polls, :user_id, false
  end

  private

    def remove_polls_without_users
      Poll.where(user_id: nil).destroy_all
    end
end
