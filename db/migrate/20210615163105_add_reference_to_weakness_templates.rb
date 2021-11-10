class AddReferenceToWeaknessTemplates < ActiveRecord::Migration[6.0]
  def change
    change_table :weakness_templates do |t|
      t.string :reference, index: true
    end
  end
end
