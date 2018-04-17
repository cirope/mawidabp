class RemoveAuditorCommentsFromFindingAnswers < ActiveRecord::Migration[5.1]
  def change
    remove_column :finding_answers, :auditor_comments
  end
end
