class ChangeTypeToQualityFindingColumns < ActiveRecord::Migration
  def change
    add_column :findings, :c_tmp, :text
    add_column :findings, :ca_tmp, :text

    Finding.reset_column_information

    raise 'no' unless Finding.all.all? { |f| f.update :c_tmp => f.correction, :ca_tmp => f.cause_analysis }

    remove_column :findings, :correction
    remove_column :findings, :cause_analysis

    rename_column :findings, :c_tmp, :correction
    rename_column :findings, :ca_tmp, :cause_analysis
  end
end
