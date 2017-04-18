class AddPollableTypeToQuestionnaires < ActiveRecord::Migration[4.2]
  def change
    add_column :questionnaires, :pollable_type, :string
  end
end
