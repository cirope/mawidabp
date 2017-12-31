class AddWeaknessTemplateToFindings < ActiveRecord::Migration[5.1]
  def change
    add_reference :findings, :weakness_template, index: true,
      foreign_key: FOREIGN_KEY_OPTIONS.dup
  end
end
