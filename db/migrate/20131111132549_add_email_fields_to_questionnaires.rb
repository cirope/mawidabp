class AddEmailFieldsToQuestionnaires < ActiveRecord::Migration
  def change
    add_column :questionnaires, :email_subject, :string
    add_column :questionnaires, :email_link, :string
    add_column :questionnaires, :email_text, :string
    add_column :questionnaires, :email_clarification, :string
  end
end
