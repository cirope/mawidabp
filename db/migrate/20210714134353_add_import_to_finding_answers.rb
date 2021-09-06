class AddImportToFindingAnswers < ActiveRecord::Migration[6.0]
  def change
    add_column :finding_answers, :imported, :boolean, default: false, null: false
  end
end
