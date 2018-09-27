module Reports::FileResponder

  def render_or_send_by_mail(collection, filename, method_name, options: {})
    if send_report_by_email?(collection)
      perform_report_and_redirect_back(collection, filename, method_name, options)
    else
      render method_name => collection.send(method_name, options), filename: filename
    end
  end

  private

    def send_report_by_email?(collection)
      SEND_REPORT_EMAIL_AFTER_COUNT && collection.unscope(:group).count > SEND_REPORT_EMAIL_AFTER_COUNT
    end

    def perform_report_and_redirect_back(collection, filename, method_name, options: {})
      AttachedReportJob.perform_later(
        model_name:      collection.model_name.name,
        ids:             collection.ids,
        user_id:         Current.user.id,
        organization_id: Current.organization.id,
        filename:        filename,
        method_name:     method_name,
        options:         options
      )

      back_url = [
        request.path,
        request.query_parameters.except('format')
      ].join('?')

      redirect_to back_url, notice: t('reports.file_will_be_sent')
    end
end
