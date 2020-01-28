class AddStateDatesToFindings < ActiveRecord::Migration[6.0]
  def change
    change_table :findings do |t|
      t.date :implemented_at, index: true
      t.date :closed_at, index: true
    end
  end
end
