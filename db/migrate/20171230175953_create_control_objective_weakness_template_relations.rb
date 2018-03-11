class CreateControlObjectiveWeaknessTemplateRelations < ActiveRecord::Migration[5.1]
  def change
    create_table :co_weakness_template_relations do |t|
      t.references :control_objective, null: false,
        index: { name: 'index_co_wt_on_co_id' },
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :weakness_template, null: false,
        index: { name: 'index_co_wt_on_wt_id' },
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
