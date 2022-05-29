class AddColumnOrganizationalUnitsToLdapConfigs < ActiveRecord::Migration[6.0]
  def change
    change_table :ldap_configs do |t|
      t.string :organizational_unit_attribute
      t.string :organizational_unit
    end
  end
end
