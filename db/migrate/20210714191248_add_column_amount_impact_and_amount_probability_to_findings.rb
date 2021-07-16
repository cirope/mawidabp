class AddColumnAmountImpactAndAmountProbabilityToFindings < ActiveRecord::Migration[6.0]
  def change
    change_table :findings do |t|
      t.decimal :amount_impact, precision: 17, scale: 2
      t.decimal :amount_probability, precision: 17, scale: 2
    end
  end
end
