new_owner   = ENV['DB_OWNER']
no_sequence = %w(ar_internal_metadata schema_migrations)

if new_owner.present?
  ActiveRecord::Base.connection.tables.each do |t|
    fix_table_owner_sql = "ALTER TABLE public.#{t} OWNER TO #{new_owner}"
    fix_seq_owner_sql   = "ALTER SEQUENCE public.#{t}_id_seq OWNER TO #{new_owner}"

    ActiveRecord::Base.connection.execute fix_table_owner_sql

    if no_sequence.exclude? t
      ActiveRecord::Base.connection.execute fix_seq_owner_sql
    end
  end
end
