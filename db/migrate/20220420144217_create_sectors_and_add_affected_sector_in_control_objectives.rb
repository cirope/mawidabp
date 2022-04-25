# frozen_string_literal: true

class CreateSectorsAndAddAffectedSectorInControlObjectives < ActiveRecord::Migration[6.1]
  def change
    create_table :sectors do |t|
      t.string :name, null: false
      t.references :organization,
                   index: true,
                   null: false,
                   foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.timestamps
    end

    add_reference :control_objectives, :affected_sector,
                  index: true,
                  foreign_key: FOREIGN_KEY_OPTIONS.dup.merge({ to_table: :sectors })
  end
end
