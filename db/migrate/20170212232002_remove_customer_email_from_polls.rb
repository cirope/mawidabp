class RemoveCustomerEmailFromPolls < ActiveRecord::Migration
  def change
    remove_column :polls, :customer_email
  end
end
