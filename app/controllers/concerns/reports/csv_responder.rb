module Reports::CSVResponder

  def render_or_send_by_mail(collection, filename, csv_options: {})
    if SEND_REPORT_EMAIL_AFTER_COUNT && collection.unscope(:group).count > SEND_REPORT_EMAIL_AFTER_COUNT
      CsvReportJob.perform_later(
        model_name:      collection.model_name.name,
        ids:             collection.ids,
        user_id:         Current.user.id,
        organization_id: Current.organization.id,
        filename:        filename,
        csv_options:     csv_options
      )

      back_url = [
        request.path,
        request.query_parameters.except('format')
      ].join('?')

      redirect_to back_url, notice: t('reports.file_will_be_sent')
    else
      render csv: collection.to_csv(csv_options), filename: filename
    end
  end
end
