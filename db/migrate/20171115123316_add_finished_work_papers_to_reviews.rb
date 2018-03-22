class AddFinishedWorkPapersToReviews < ActiveRecord::Migration[5.1]
  def change
    add_column :reviews, :finished_work_papers, :boolean, default: false, null: false
  end
end
