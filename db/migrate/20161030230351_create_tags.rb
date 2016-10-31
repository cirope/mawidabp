class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name, null: false, index: true
      t.string :kind, null: false, index: true
      t.string :style, null: false
      t.references :organization, index: true, null: false
      t.integer :lock_version, default: 0

      if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
        t.jsonb :options, index: { using: :gin }
      else
        t.text :options, index: true
      end

      t.timestamps null: false
    end

    add_foreign_key :tags, :organizations, FOREIGN_KEY_OPTIONS.dup
  end
end
