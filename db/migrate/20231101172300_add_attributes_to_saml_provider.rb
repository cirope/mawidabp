class AddAttributesToSamlProvider < ActiveRecord::Migration[6.1]
  def change
    change_table :saml_providers do |t|
      t.string :username_claim
      t.string :name_claim
      t.string :lastname_claim
      t.string :email_claim
      t.string :roles_claim
    end
  end
end
