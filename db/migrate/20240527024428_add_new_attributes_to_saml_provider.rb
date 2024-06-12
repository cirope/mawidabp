class AddNewAttributesToSamlProvider < ActiveRecord::Migration[6.1]
  def change
    change_table :saml_providers do |t|
      t.string :function_claim
      t.string :manager_claim
    end
  end
end
