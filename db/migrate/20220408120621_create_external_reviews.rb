class CreateExternalReviews < ActiveRecord::Migration[6.1]
  def change
    create_table :external_reviews do |t|
      t.references :review
      t.references :alternative_review

      t.timestamps
    end
  end
end
