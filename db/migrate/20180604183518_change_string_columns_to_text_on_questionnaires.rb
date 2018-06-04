class ChangeStringColumnsToTextOnQuestionnaires < ActiveRecord::Migration[5.1]
  def change
    add_column :questionnaires, :tmp_email_text, :text
    add_column :questionnaires, :tmp_email_clarification, :text

    Questionnaire.reset_column_information

    raise 'no' unless Questionnaire.all.all? { |q| q.update tmp_email_text: q.email_text, tmp_email_clarification: q.email_clarification }

    remove_column :questionnaires, :email_text
    remove_column :questionnaires, :email_clarification

    rename_column :questionnaires, :tmp_email_text, :email_text
    rename_column :questionnaires, :tmp_email_clarification, :email_clarification
  end
end
