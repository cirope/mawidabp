class AddSettingsToOrganizations < ActiveRecord::Migration[6.1]
  def change
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      add_column :organizations, :settings, :jsonb, default: {}, null: false
      add_index :organizations, :settings, using: :gin
    else
      add_column :organizations, :settings, :text, default: '{}', null: false
    end
  end
end
