class AddOptionsToOrganizations < ActiveRecord::Migration[6.1]
  def change
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      add_column :organizations, :options, :jsonb
      add_index  :organizations, :options, using: :gin
    else
      add_column :organizations, :options, :text
      add_index  :organizations, :options
    end
  end
end
