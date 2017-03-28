class ChangeTypeToQualityFindingColumns < ActiveRecord::Migration[4.2]
  def change
    change_column :findings, :correction, :text
    change_column :findings, :cause_analysis, :text
  end
end
