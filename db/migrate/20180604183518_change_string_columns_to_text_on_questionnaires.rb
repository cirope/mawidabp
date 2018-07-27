class ChangeStringColumnsToTextOnQuestionnaires < ActiveRecord::Migration[5.1]
  def change
    change_column :questionnaires, :email_text, :text
    change_column :questionnaires, :email_clarification, :text
  end
end
