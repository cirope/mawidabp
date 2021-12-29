module Findings::ImplementedNotifications
  extend ActiveSupport::Concern

  module ClassMethods
    def notify_implemented_findings_with_follow_up_date_last_changed_greater_than_90_days
      findings = Finding.where(final: false, state: Finding::STATUS['implemented'])
                        .where("follow_up_date_last_changed + '90 DAY'::INTERVAL > ?", Time.zone.today)
      
      findings.each do |finding|
        NotifierMailer.notify_implemented_finding_with_follow_up_date_last_changed_greater_than_90_days(finding)
                      .deliver_later
      end
    end
  end
end
