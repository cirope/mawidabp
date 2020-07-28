class AddFileModelToWorkflows < ActiveRecord::Migration[6.0]
  def change
    change_table :workflows do |t|
      t.references :file_model, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
    end
  end
end
