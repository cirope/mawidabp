class ChangeTypeToQualityFindingColumns < ActiveRecord::Migration
  def change
    change_column :findings, :correction, :text
    change_column :findings, :cause_analysis, :text
  end
end
