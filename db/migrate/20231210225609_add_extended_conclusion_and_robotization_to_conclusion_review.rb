class AddExtendedConclusionAndRobotizationToConclusionReview < ActiveRecord::Migration[6.1]
  def change
    add_column :conclusion_reviews, :extended_conclusion, :text
    add_column :conclusion_reviews, :robotization, :text
  end
end
