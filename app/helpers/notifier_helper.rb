module NotifierHelper
  def finding_audited_names(finding)
    finding.users.select do |user|
      corporate_organization_ids = user.organizations.corporate.map(&:id)
      audited_on_current_org     = user.can_act_as_audited?
      audited_on_corporate_orgs  = corporate_organization_ids.any? { |id| user.can_act_as_audited_on?(id) }

      audited_on_current_org || (audited_on_current_org && audited_on_corporate_orgs)
    end.map do |user|
      if finding.process_owners.include? user
        content_tag :b,
          "#{user.full_name} (#{FindingUserAssignment.human_attribute_name('process_owner')})"
      else
        user.full_name
      end
    end
  end
end
