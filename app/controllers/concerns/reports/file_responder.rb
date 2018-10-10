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
      collection.unscope(:group).count > SEND_REPORT_EMAIL_AFTER_COUNT
    end

    def perform_report_and_redirect_back args
      collection  = args.fetch :collection
      filename    = [args.fetch(:filename), request.format.symbol].join '.'
      method_name = args.fetch(:method_name).to_s
      options     = args.fetch :options, {}

      byebug
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

      if (where_clause = values.delete(:where))
        wheres = where_clause.send(:predicates).map do |predicate|
          if predicate.is_a?(String)
            predicate
          else
            value = predicate.right.value.value_for_database
            value_for_db = value.is_a?(Numeric) ? value.to_s : ActiveRecord::Base.qcn(value)

            predicate.to_sql.gsub('$1', value_for_db)
          end
        end

        values[:where] = wheres.map {|w| "(#{w})"}.join(' AND ')
      end

      if (orders = values.delete(:order))
        values[:order] = orders.map do |o|
          o.try(:to_sql) || o.to_s # raw order
        end.join(', ')
      end

      values.to_json
    end
end
