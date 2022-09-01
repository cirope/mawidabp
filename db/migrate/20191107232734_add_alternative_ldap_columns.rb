class AddAlternativeLdapColumns < ActiveRecord::Migration[6.0]
  def change
    change_table :ldap_configs do |t|
      t.string  :alternative_hostname
      t.integer :alternative_port
    end
  end
end
