class AddAttributesToSamlProvider < ActiveRecord::Migration[6.1]
  def change
    change_table :saml_providers do |t|
      t.string :username_attribute
      t.string :name_attribute
      t.string :lastname_attribute
      t.string :email_attribute
      t.string :roles_attribute
    end
  end
end
