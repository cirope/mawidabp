class AddAttachedToAnswers < ActiveRecord::Migration[6.1]
  def change
    add_column :answers, :attached, :string
  end
end
