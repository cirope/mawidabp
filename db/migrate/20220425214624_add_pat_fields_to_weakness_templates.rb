class AddPatFieldsToWeaknessTemplates < ActiveRecord::Migration[6.1]
  def change
    add_column :weakness_templates, :brief, :text
    add_column :weakness_templates, :subreference, :string
    add_column :weakness_templates, :failure, :boolean, default: false, null: false
  end
end
