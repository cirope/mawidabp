module Findings::ImplementedNotifications
  extend ActiveSupport::Concern

  module ClassMethods
    def notify_implemented_findings_with_follow_up_date_greater_than_90_days
      findings = Finding.where(final: false, state: Finding::STATUS['implemented'])
                        .where('follow_up_date > ?', Time.zone.today)

      if findings.present?
        NotifierMailer.notify_implemented_finding_greater_than_90_days(findings)
                      .deliver_later
      end
    end
  end
end
