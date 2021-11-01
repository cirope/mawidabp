class AddExcludeRegularizedFindingsToConclusionReviews < ActiveRecord::Migration[6.0]
  def change
    add_column :conclusion_reviews, :exclude_regularized_findings, :boolean, default: false, null: false
  end
end
