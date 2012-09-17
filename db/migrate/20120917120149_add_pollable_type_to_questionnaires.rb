class AddPollableTypeToQuestionnaires < ActiveRecord::Migration
  def change
    add_column :questionnaires, :pollable_type, :string
  end
end
