class AddBriefToFindings < ActiveRecord::Migration[6.0]
  def change
    change_table :findings do |t|
      t.text :brief
    end
  end
end
