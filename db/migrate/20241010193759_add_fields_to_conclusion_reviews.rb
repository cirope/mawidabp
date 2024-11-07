class AddFieldsToConclusionReviews < ActiveRecord::Migration[6.1]
  def change
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      add_column :conclusion_reviews, :fields, :jsonb, default: {}, null: false
    else
      add_column :conclusion_reviews, :fields, :text, default: '{}', null: false
    end
  end
end
