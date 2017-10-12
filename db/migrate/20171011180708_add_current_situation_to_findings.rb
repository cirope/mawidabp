class AddCurrentSituationToFindings < ActiveRecord::Migration[5.1]
  def change
    change_table :findings do |t|
      t.text :current_situation
      t.boolean :current_situation_verified, null: false, default: false
    end
  end
end
