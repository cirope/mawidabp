class AddAditionalCommentsToConclusionReviews < ActiveRecord::Migration[6.0]
  def change
    change_table :conclusion_reviews do |t|
      t.text :additional_comments
    end
  end
end
