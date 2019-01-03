require 'sequel'

CHECK_RESULTS = ENV['CHECK_RESULTS'].present?

logger = ::Logger.new('log/migration_to_pg.log')

oracle_db = Sequel.oracle "//192.168.0.108:1521/mawidabp", user: 'system', password: 'mawidabp'
pg_db = Sequel.postgres 'mawidabp_migration',
  user:     'docker',
  password: 'docker',
  host:     'localhost',
  port:     5432

oracle_db.extension(:pagination)

Rails.application.eager_load!; nil
models = (ApplicationRecord.descendants + [PaperTrail::Version]).flatten.uniq { |m| m.table_name }; nil

# Ignore ForeignKeyViolation
pg_db.execute "SET session_replication_role = 'replica';" unless CHECK_RESULTS

models.each do |model|
  table_name   =  model.table_name.to_sym

  logger.info '='*60
  logger.info [
    CHECK_RESULTS ? 'Checking' : 'Migrating',
    table_name
  ].join(' ')

  pg_table = if table_name == :co_weakness_template_relations
               pg_db[:control_objective_weakness_template_relations]
             else
               pg_db[table_name]
             end

  oracle_table = if table_name == :control_objective_weakness_template_relations
                   oracle_db[:co_weakness_template_relations]
                 else
                   oracle_db[table_name]
                 end


  columns = model.columns.map(&:name).map(&:to_sym)

  begin
    next if !CHECK_RESULTS && (pg_table.count == oracle_table.count)
  rescue => e
    logger.info "Error: #{e}"
    next
  end

  oracle_table.order(:id).each_page(2000) do |group|
    last_id = nil
    group.each do |row|
      last_id = row[:id]

      begin
        a = row.slice(*columns)

        case table_name
        when :error_records
          a[:data].delete!("\000")
        when :findings, :weakness_templates
          [:operational_risk, :impact, :internal_control_components].each do |attr|
            a[attr] = a[attr].to_s.gsub(/^\[/, '{').gsub(/\]$/, '}')
          end
        when :versions
          if a[:object].present?
            obj = JSON.parse a[:object].gsub(/\\u000/, '')
            obj.clone.each do |k, v|
              obj[k] = v['value'] if (v.is_a?(Hash) && v.key?('value'))
            end
            a[:object] = obj.to_json
          end

          if a[:object_changes].present?
            obj_changes = JSON.parse a[:object_changes].gsub(/\\u000/, '')
            obj_changes.clone.each do |k, (old_v, new_v)|
              obj_changes[k] = [
                (old_v.is_a?(Hash) && old_v.key?('value')) ? old_v['value'] : old_v,
                (new_v.is_a?(Hash) && new_v.key?('value')) ? new_v['value'] : new_v,
              ]
            end
            a[:object_changes] = obj_changes.to_json
          end
        end

        if CHECK_RESULTS
          a.dup.each do |k, v|
            if v.present?
              column = model.columns.select {|c| c.name.to_s == k.to_s }.first
              if column.sql_type == 'boolean'
                a[k] = true if v == 'Y'
                a[k] = false if v == 'N'
              elsif column.sql_type.to_sym == :date
                a[k] = v.to_date
              elsif column.sql_type.to_s == 'timestamp without time zone'
                a[k] = v.to_time
              elsif column.sql_type.to_sym == :datetime
                a[k] = v.to_datetime
              end
            end
          end

          unless (pg_a = pg_table.where(id: a[:id]).first) == a
            # byebug
            @tanga ||= ::Logger.new('no-iguales-error.log')
            @tanga.info "============ #{table_name} ==============="
            @tanga.info a
            @tanga.info pg_a
          end
        else
          pg_table.insert(a)
        end

      rescue => e
        logger.info "Error: #{e.to_s}"
      end
    end

    logger.info "Table #{table_name} in progress => done: #{pg_table.count}" unless CHECK_RESULTS
  end
  logger.info "PG count: #{pg_table.count} Oracle count: #{oracle_table.count}" unless CHECK_RESULTS
end

pg_db.execute "SET session_replication_role = 'origin';" unless CHECK_RESULTS

return if CHECK_RESULTS

sql = <<-SQL.delete("\n").squish
  SELECT 'SELECT SETVAL(' ||
    quote_literal(quote_ident(PGT.schemaname) || '.' || quote_ident(S.relname)) ||
    ', COALESCE(MAX(' ||quote_ident(C.attname)|| '), 1) ) FROM ' ||
    quote_ident(PGT.schemaname)|| '.'||quote_ident(T.relname)|| ';'
  FROM pg_class AS S,
    pg_depend AS D,
    pg_class AS T,
    pg_attribute AS C,
    pg_tables AS PGT
  WHERE S.relkind = 'S'
    AND S.oid = D.objid
    AND D.refobjid = T.oid
    AND D.refobjid = C.attrelid
    AND D.refobjsubid = C.attnum
    AND T.relname = PGT.tablename
  ORDER BY S.relname;
SQL

sequences = pg_db[sql].to_a.map(&:values).flatten.uniq;nil

return if sequences.empty?

logger.info '='*60
logger.info 'Resetting sequencies'

sequences.each do |s|
  logger.info(s)
  pg_db[s]
end;nil
