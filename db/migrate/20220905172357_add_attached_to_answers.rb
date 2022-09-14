class AddAttachedToAnswers < ActiveRecord::Migration[6.0]
  def change
    add_column :answers, :attached, :string
  end
end
