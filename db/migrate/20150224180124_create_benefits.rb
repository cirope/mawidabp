class CreateBenefits < ActiveRecord::Migration
  def change
    create_table :benefits do |t|
      t.string :name, null: false
      t.string :kind, null: false
      t.references :organization, index: true, null: false

      t.timestamps
    end

    add_foreign_key :benefits, :organizations, FOREIGN_KEY_OPTIONS.dup
  end
end
