class AddCustomerEmailToPolls < ActiveRecord::Migration[4.2]
  def change
    add_column :polls, :customer_email, :string

    add_index :polls, :customer_email
  end
end
