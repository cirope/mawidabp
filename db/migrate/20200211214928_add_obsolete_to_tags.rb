class AddObsoleteToTags < ActiveRecord::Migration[6.0]
  def change
    default = if ActiveRecord::Base.connection.adapter_name == 'OracleEnhanced'
                'N'
              else
                false
              end

    change_table :tags do |t|
      t.boolean :obsolete, null: false, default: default
    end

    add_index :tags, :obsolete
  end
end
