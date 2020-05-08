class CreateEndorsements < ActiveRecord::Migration[6.0]
  def change
    create_table :endorsements do |t|
      t.string :status, null: false
      t.references :user, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :finding_answer, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
