class AddOfficeToUsers < ActiveRecord::Migration[6.0]
  def change
    change_table :users do |t|
      t.string :office
    end
  end
end
