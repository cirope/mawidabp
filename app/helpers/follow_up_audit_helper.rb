module FollowUpAuditHelper
  def weaknesses_brief_audit_users weakness
    weakness.
      finding_user_assignments.
      select { |fua| fua.user.can_act_as_audited? }.
      map(&:user).
      map(&:full_name)
  end
end
