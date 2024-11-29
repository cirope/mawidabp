class AddStatusToReviews < ActiveRecord::Migration[6.1]
  def change
    add_column :reviews, :status, :string, null: false, default: 'draft'
    add_index :reviews, :status
  end
end
