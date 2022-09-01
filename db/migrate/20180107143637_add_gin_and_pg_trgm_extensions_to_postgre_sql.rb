class AddGinAndPgTrgmExtensionsToPostgreSql < ActiveRecord::Migration[5.1]
  def up
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      enable_extension('btree_gin') unless extensions.include?('btree_gin')
      enable_extension('pg_trgm')   unless extensions.include?('pg_trgm')
    end
  end

  def down
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      disable_extension('btree_gin') if extensions.include?('btree_gin')
      disable_extension('pg_trgm')   if extensions.include?('pg_trgm')
    end
  end
end
