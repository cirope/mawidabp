class ChangeFileModelsFileSizeTypeToBigInt < ActiveRecord::Migration[5.2]
  def change
    if ActiveRecord::Base.connection.adapter_name == 'OracleEnhanced'
      change_column :file_models, :file_file_size, :decimal, precision: 38, scale: 0
    else
      change_column :file_models, :file_file_size, :bigint
    end
  end
end

