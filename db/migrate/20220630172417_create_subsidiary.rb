class CreateSubsidiary < ActiveRecord::Migration[6.1]
  def change
    create_table :subsidiaries do |t|
      t.string :name
      t.string :identity
      t.references :organization,
                   index: true,
                   null: false,
                   foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.timestamps
    end

    add_reference :reviews, :subsidiary, index: true,
                                         foreign_key: FOREIGN_KEY_OPTIONS.dup
  end
end
