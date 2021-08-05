class AddAnnexsToConclusionDraftReview < ActiveRecord::Migration[6.0]
  def change
    create_table :annexes do |t|
      t.string "title", null: false
      t.text "description", null: true
      t.belongs_to :conclusion_review, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.timestamps
    end
  end
end
