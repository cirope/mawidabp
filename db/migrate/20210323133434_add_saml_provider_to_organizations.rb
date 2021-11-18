class AddSamlProviderToOrganizations < ActiveRecord::Migration[6.0]
  def change
    change_table :organizations do |t|
      t.string :saml_provider
    end
  end
end
