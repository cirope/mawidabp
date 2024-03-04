class ApplicationMailer < ActionMailer::Base
default from: "#{ENV['EMAIL_NAME'] || I18n.t('app_name')} <#{ENV['EMAIL_ADDRESS']}>",
        return_path: ENV['RETURN_PATH'] || ''

  def mail args
    headers(
      'Auto-Submitted'           => true,
      'X-Auto-Response-Suppress' => 'All',
      'Precedence'               => 'Bulk'
    )

    super args
  end
end
