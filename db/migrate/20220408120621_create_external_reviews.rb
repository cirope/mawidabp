class CreateExternalReviews < ActiveRecord::Migration[6.1]
  def change
    create_table :external_reviews do |t|
      t.references :review
      t.bigint :reference_review_id

      t.timestamps
    end
  end
end
