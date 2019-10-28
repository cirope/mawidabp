class AddPaidUntilToLicenses < ActiveRecord::Migration[6.0]
  def change
    remove_index :licenses, :subscribed_until
    remove_column :licenses, :subscribed_until

    add_column :licenses, :paid_until, :datetime

    add_index :licenses, :paid_until
  end
end
