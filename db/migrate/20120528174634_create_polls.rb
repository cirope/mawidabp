class CreatePolls < ActiveRecord::Migration
  def change
    create_table :polls do |t|
      t.text :comments
      t.references :questionnaire
      t.timestamps
    end
  end
end
