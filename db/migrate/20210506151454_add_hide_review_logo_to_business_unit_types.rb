class AddHideReviewLogoToBusinessUnitTypes < ActiveRecord::Migration[6.0]
  def change
    change_table :business_unit_types do |t|
      t.boolean :hide_review_logo, null: false, default: false
    end
  end
end
