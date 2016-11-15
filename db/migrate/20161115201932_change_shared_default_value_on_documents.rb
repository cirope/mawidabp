class ChangeSharedDefaultValueOnDocuments < ActiveRecord::Migration
  def change
    change_column_default :documents, :shared, false
  end
end
