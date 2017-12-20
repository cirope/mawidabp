class ChangeFinishedWorkPapersTypeOnReviews < ActiveRecord::Migration[5.1]
  class Review < ActiveRecord::Base
  end

  def change
    add_column :reviews, :finished_work_papers_enum, :integer, default: 0, null: false

    Review.reset_column_information

    Review.all.each do |review|
      value = review.finished_work_papers ? 1 : 0

      review.update_column :finished_work_papers_enum, value
    end

    remove_column :reviews, :finished_work_papers
    rename_column :reviews, :finished_work_papers_enum, :finished_work_papers
  end
end
