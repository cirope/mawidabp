class AddOfficeAttributeToLdapConfigs < ActiveRecord::Migration[6.0]
  def change
    change_table :ldap_configs do |t|
      t.string :office_attribute
    end
  end
end
