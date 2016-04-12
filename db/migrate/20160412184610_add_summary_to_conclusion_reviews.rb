class AddSummaryToConclusionReviews < ActiveRecord::Migration
  def change
    add_column :conclusion_reviews, :summary, :string

    add_index :conclusion_reviews, :summary
  end
end
