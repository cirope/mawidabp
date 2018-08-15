module Findings::Brief
  extend ActiveSupport::Concern

  module ClassMethods

    def send_brief
      brief_parameters.each do |organization, value|
        date = FINDING_INITIAL_BRIEF_DATE
        send = value > 0 && (Time.zone.today - date) % (7 * value) == 0

        if send
          Current.organization = organization
          users = organization.users.list_all_with_pending_findings

          users.each do |user|
            findings = user.findings.list.with_pending_status.finals false

            NotifierMailer.findings_brief(user, findings.to_a).deliver_later
          end
        end
      end
    end

    private

      def brief_parameters
        Organization.all_parameters('brief_period_in_weeks').map do |p|
          [p[:organization], p[:parameter].to_i]
        end
      end
  end
end
