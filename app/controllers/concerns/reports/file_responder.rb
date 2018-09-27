module Reports::FileResponder

  def render_or_send_by_mail args
    collection  = args[:collection]
    filename    = args[:filename]
    method_name = args[:method_name]
    options     = args[:options] || {}

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
      collection  = args[:collection]
      filename    = [args[:filename], request.format.symbol].join('.')
      method_name = args[:method_name].to_s
      options     = args[:options] || {}

      AttachedReportJob.perform_later(
        model_name:      collection.model_name.name,
        ids:             collection.ids,
        user_id:         Current.user.id,
        organization_id: Current.organization.id,
        filename:        filename,
        method_name:     method_name,
        options:         options
      )

      parameters = request.query_parameters.except('format')

      back_url = if parameters.present?
                   [request.path, parameters.to_param].join '?'
                 else
                   request.path
                 end

      redirect_to back_url, notice: t('reports.file_will_be_sent')
    end
end
