class AddLatestToFindings < ActiveRecord::Migration[6.0]
  def change
    change_table :findings do |t|
      t.references :latest, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup.merge(
        column: :latest_id, to_table: :findings
      )
    end
  end
end
