class ChangeFileModelsFileSizeTypeToBigInt < ActiveRecord::Migration[5.2]
  def change
    change_column :file_models, :file_file_size, :bigint
  end
end
