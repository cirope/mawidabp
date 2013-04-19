class AddCustomerEmailToPolls < ActiveRecord::Migration
  def change
    add_column :polls, :customer_email, :string

    add_index :polls, :customer_email
  end
end
