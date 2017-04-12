class ChangeSharedDefaultValueOnDocuments < ActiveRecord::Migration[4.2]
  def change
    change_column_default :documents, :shared, false
  end
end
