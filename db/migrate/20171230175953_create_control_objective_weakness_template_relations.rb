class CreateControlObjectiveWeaknessTemplateRelations < ActiveRecord::Migration[5.1]
  def change
    create_table :control_objective_weakness_template_relations do |t|
      t.references :control_objective, null: false,
        index: { name: 'index_co_wt_on_control_objective_id' },
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :weakness_template, null: false,
        index: { name: 'index_co_wt_on_weakness_template_id' },
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
