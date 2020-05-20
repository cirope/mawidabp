class CreateCommitmentSupports < ActiveRecord::Migration[6.0]
  def change
    create_table :commitment_supports do |t|
      t.text :reason, null: false
      t.text :plan, null: false
      t.text :controls, null: false
      t.references :finding_answer, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
