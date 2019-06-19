class CreatePermalinkModels < ActiveRecord::Migration[5.2]
  def change
    create_table :permalink_models do |t|
      t.references :permalink, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :model, null: false, index: true, polymorphic: true

      t.datetime :created_at, null: false
    end
  end
end
