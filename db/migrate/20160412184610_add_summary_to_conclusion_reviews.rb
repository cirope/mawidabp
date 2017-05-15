class AddSummaryToConclusionReviews < ActiveRecord::Migration[4.2]
  def change
    add_column :conclusion_reviews, :summary, :string

    add_index :conclusion_reviews, :summary
  end
end
