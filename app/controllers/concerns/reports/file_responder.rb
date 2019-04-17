module Reports::FileResponder

  def render_or_send_by_mail args
    collection  = args.fetch :collection
    filename    = args.fetch :filename
    method_name = args.fetch :method_name
    options     = args.fetch :options, {}

    if send_report_by_email? collection
      perform_report_and_redirect_back args
    else
      render request.format.symbol => collection.send(method_name, options), filename: filename
    end
  end

  private

    def send_report_by_email? collection
      collection.unscope(
        :group, :order, :select, :having, :limit, :offset
      ).select(
        "#{collection.model.quoted_table_name}.#{collection.model.qcn 'id'}"
      ).distinct.count > SEND_REPORT_EMAIL_AFTER_COUNT
    end

    def perform_report_and_redirect_back args
      collection  = args.fetch :collection
      filename    = [args.fetch(:filename), request.format.symbol].join '.'
      method_name = args.fetch(:method_name).to_s
      options     = args.fetch :options, {}

      AttachedReportJob.perform_later(
        model_name:      collection.model_name.name,
        query_methods:   report_query_methods(collection),
        user_id:         Current.user.id,
        organization_id: Current.organization.id,
        filename:        filename,
        method_name:     method_name,
        options:         options
      )

      parameters = request.query_parameters.except 'format'

      back_url = if parameters.present?
                   [request.path, parameters.to_param].join '?'
                 else
                   request.path
                 end

      redirect_to back_url, notice: t('reports.file_will_be_sent')
    end

    def report_query_methods collection
      values = collection.values
      values = report_where_clauses values
      values = report_order_clauses values

      values.to_json
    end

    def report_where_clauses values
      if (where_clause = values.delete :where)
        wheres       = []
        where_tables = []

        where_clause.send(:predicates).map do |predicate|
          if predicate.is_a? String
            wheres << predicate
          else
            where_tables << predicate.left.relation.name
          end
        end

        where_hash = where_tables.uniq.each_with_object({}) do |table, memo|
          memo[table] = where_clause.to_h table
        end

        wheres << where_hash if where_hash.any?

        values[:where] = wheres
      end

      values
    end

    def report_order_clauses values
      if (orders = values.delete :order)
        values[:order] = orders.map do |o|
          o.try(:to_sql) || o.to_s # raw order
        end
      end

      values
    end
end
