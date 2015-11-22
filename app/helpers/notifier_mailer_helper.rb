module NotifierMailerHelper
  def finding_audited_names(finding)
    finding.users.select(&:can_act_as_audited?).map do |user|
      if finding.process_owners.include? user
        content_tag :b,
          "#{user.full_name} (#{FindingUserAssignment.human_attribute_name('process_owner')})"
      else
        user.full_name
      end
    end
  end
end
