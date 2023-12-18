module ReportsHelper
  def pdf_and_csv_download_links
    [
      link_to(t('label.download'), '#', data: { bs_toggle: 'modal', target: '#customize_report' }),
      link_to(t('label.download_csv'), params: request.query_parameters.merge(format: :csv))
    ].join(' | ').html_safe
  end
end
