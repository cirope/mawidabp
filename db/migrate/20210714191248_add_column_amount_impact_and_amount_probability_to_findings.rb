class AddColumnAmountImpactAndAmountProbabilityToFindings < ActiveRecord::Migration[6.0]
  def change
    change_table :findings do |t|
      t.decimal :impact_amount, precision: 17, scale: 2
      t.decimal :probability_amount, precision: 17, scale: 2
    end
  end
end
