class CreateRelatedUserRelations < ActiveRecord::Migration[4.2]
  def change
    create_table :related_user_relations do |t|
      t.references :user
      t.references :related_user

      t.timestamps null: false
    end

    add_index :related_user_relations, [:user_id, :related_user_id]
  end
end
