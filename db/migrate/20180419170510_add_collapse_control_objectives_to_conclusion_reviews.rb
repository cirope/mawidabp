class AddCollapseControlObjectivesToConclusionReviews < ActiveRecord::Migration[5.1]
  def change
    add_column :conclusion_reviews, :collapse_control_objectives, :boolean, null: false, default: false
  end
end
