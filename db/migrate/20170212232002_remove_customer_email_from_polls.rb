class RemoveCustomerEmailFromPolls < ActiveRecord::Migration[4.2]
  def change
    remove_column :polls, :customer_email
  end
end
