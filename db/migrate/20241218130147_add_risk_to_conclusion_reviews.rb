class AddRiskToConclusionReviews < ActiveRecord::Migration[6.1]
  def change
    add_column :conclusion_reviews, :risk, :integer
  end
end
