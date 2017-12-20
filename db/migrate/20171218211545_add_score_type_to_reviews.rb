class AddScoreTypeToReviews < ActiveRecord::Migration[5.1]
  def change
    add_column :reviews, :score_type, :string, null: false, default: 'effectiveness'
  end
end
