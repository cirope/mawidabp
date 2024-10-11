class AddOptionsToConclusionReviews < ActiveRecord::Migration[6.1]
  def change
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      add_column :conclusion_reviews, :options, :jsonb, default: {}, null: false
      add_index :conclusion_reviews, :options, using: :gin
    else
      add_column :conclusion_reviews, :options, :text, default: '{}', null: false
    end

    # Note: The 'exclude_regularized_findings' column will be removed in a future migration
    change_column_null :conclusion_reviews, :exclude_regularized_findings, true
  end
end
