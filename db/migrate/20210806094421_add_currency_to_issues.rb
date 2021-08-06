class AddCurrencyToIssues < ActiveRecord::Migration[6.0]
  def change
    change_table :issues do |t|
      t.string :currency
    end
  end
end
