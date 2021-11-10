class AddColumnNotesToWeaknessTemplates < ActiveRecord::Migration[6.0]
  def change
    change_table :weakness_templates do |t|
      t.text :notes
    end
  end
end
