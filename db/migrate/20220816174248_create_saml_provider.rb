class CreateSamlProvider < ActiveRecord::Migration[6.1]
  def change
    create_table :saml_providers do |t|
      t.string     :provider, null: false
      t.string     :idp_homepage, null: false
      t.string     :idp_entity_id, null: false
      t.string     :idp_sso_target_url, null: false
      t.string     :sp_entity_id, null: false
      t.string     :assertion_consumer_service_url, null: false
      t.string     :name_identifier_format, null: false
      t.string     :assertion_consumer_service_binding, null: false
      t.text       :idp_cert, null: false
      t.references :organization,
                   index: true,
                   null: false,
                   foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.timestamps
    end
  end
end
